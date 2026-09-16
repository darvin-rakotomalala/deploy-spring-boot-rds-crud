#######################################################
# IAM role for Terraform execution (used in CI/CD)
#######################################################

resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "terraform_execution" {
  name = "${var.naming_prefix}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${var.current_account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}*/${var.github_repo}*:*"
          }
        }
      }
    ]
  })

  # Maximum session duration (1 hour for Terraform runs)
  max_session_duration = 3600

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-ga-oidc"
  })
}

resource "aws_iam_role_policy_attachment" "terraform_execution_admin" {
  role       = aws_iam_role.terraform_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

############################################
# IAM Role & Instance Profile for EC2 Application Tier
############################################

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_app" {
  name               = "${var.naming_prefix}-ec2-app-role"
  description        = "Instance role for the Spring Boot application EC2 servers"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-ec2-app-role"
  })
}

# ---------- AWS managed policies ----------

# SSM Agent management (Session Manager, Run Command, State Manager)
resource "aws_iam_role_policy_attachment" "ec2_ssm_core" {
  role       = aws_iam_role.ec2_app.name
  policy_arn = "arn:${var.current_partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch Agent: publish custom metrics (CPU, memory, disk) and logs
resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_agent" {
  role       = aws_iam_role.ec2_app.name
  policy_arn = "arn:${var.current_partition}:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# RDS full access, per Technical Spec Step 17 requirement
resource "aws_iam_role_policy_attachment" "ec2_rds_full_access" {
  role       = aws_iam_role.ec2_app.name
  policy_arn = "arn:${var.current_partition}:iam::aws:policy/AmazonRDSFullAccess"
}

# ---------- Custom least-privilege policy: S3 (JAR bucket), KMS, Secrets Manager, Logs ----------
data "aws_iam_policy_document" "ec2_app_custom" {
  # Read-only access to the specific JAR artifact bucket
  statement {
    sid    = "ReadJarArtifactBucket"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
    ]
    resources = [
      "arn:${var.current_partition}:s3:::${var.jar_bucket_name}",
      "arn:${var.current_partition}:s3:::${var.jar_bucket_name}/*",
    ]
  }

  # Allow this role to send SSM commands to the target EC2 instance(s)
  statement {
    sid    = "AllowSSMSendCommandToInstance"
    effect = "Allow"
    actions = [
      "ssm:SendCommand"
    ]
    resources = concat(
      [for id in var.ec2_instance_ids : "arn:${var.current_partition}:ec2:${var.primary_region}:${var.current_account_id}:instance/${id}"],
      [
        "arn:${var.current_partition}:ssm:${var.primary_region}::document/AWS-RunShellScript",
        "arn:${var.current_partition}:ssm:${var.primary_region}::document/AWS-RunPowerShellScript",
        "arn:${var.current_partition}:ssm:${var.primary_region}::document/AWS-ConfigureAWSPackage"
      ]
    )
  }

  # Permissions to retrieve SSM documents and Distributor packages
  statement {
    sid    = "AllowSSMGetDocumentForPackages"
    effect = "Allow"
    actions = [
      "ssm:GetDocument",
      "ssm:DescribeDocument"
    ]
    resources = [
      "arn:${var.current_partition}:ssm:*:*:package/AmazonCloudWatchAgent",
      "arn:${var.current_partition}:ssm:*:*:document/*"
    ]
  }

  # Allow reading command invocation results
  statement {
    sid    = "AllowSSMReadCommandResults"
    effect = "Allow"
    actions = [
      "ssm:GetCommandInvocation",
      "ssm:ListCommandInvocations",
      "ssm:ListCommands"
    ]
    resources = ["*"]
  }

  # Improved KMS Decryption: Allows dynamic KMS keys via ARN patterns with ViaService constraints
  statement {
    sid    = "UseKmsKeysForDecryption"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
    ]
    resources = concat(
      [
        var.kms_key_rds_arn,
        var.kms_key_secrets_arn,
        var.kms_key_cloudwatch_arn,
      ]
    )

    # Security Guardrail: Prevent key misuse outside intended services
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values = [
        "secretsmanager.${var.primary_region}.amazonaws.com",
        "s3.${var.primary_region}.amazonaws.com",
        "logs.${var.primary_region}.amazonaws.com"
      ]
    }
  }

  # Read the RDS master credentials secret
  statement {
    sid       = "ReadDatabaseCredentialsSecret"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = [var.secretsmanager_db_credentials_arn]
  }

  # Write application logs / metrics to CloudWatch
  statement {
    sid    = "WriteApplicationLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]
    resources = [
      "${var.log_group_app_tier_arn}:*",
      var.log_group_app_tier_arn,
    ]
  }

  # Describe RDS instance for connection/health diagnostics
  statement {
    sid       = "DescribeRds"
    effect    = "Allow"
    actions   = ["rds:DescribeDBInstances"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ec2_app_custom" {
  name        = "${var.naming_prefix}-ec2-app-policy"
  description = "Least-privilege access to S3 JAR bucket, KMS keys, Secrets Manager and CloudWatch Logs"
  policy      = data.aws_iam_policy_document.ec2_app_custom.json
}

resource "aws_iam_role_policy_attachment" "ec2_app_custom" {
  role       = aws_iam_role.ec2_app.name
  policy_arn = aws_iam_policy.ec2_app_custom.arn
}

resource "aws_iam_instance_profile" "ec2_app" {
  name = "${var.naming_prefix}-ec2-app-profile"
  role = aws_iam_role.ec2_app.name

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-ec2-app-profile"
  })
}

############################################
# IAM Role for RDS Enhanced Monitoring
############################################

data "aws_iam_policy_document" "rds_monitoring_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  name               = "${var.naming_prefix}-rds-enhanced-monitoring-role"
  description        = "Allows RDS to publish enhanced monitoring metrics to CloudWatch Logs"
  assume_role_policy = data.aws_iam_policy_document.rds_monitoring_assume_role.json

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-rds-enhanced-monitoring-role"
  })
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:${var.current_partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

############################################
# KMS Key Policy for CloudWatch & SNS Encryption
############################################

data "aws_iam_policy_document" "kms_cloudwatch_policy" {
  statement {
    sid       = "EnableIAMUserPermissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:${var.current_partition}:iam::${var.current_account_id}:root"]
    }
  }

  statement {
    sid    = "AllowCloudWatchLogsServiceUse"
    effect = "Allow"
    actions = [
      "kms:Encrypt*", "kms:Decrypt*", "kms:ReEncrypt*",
      "kms:GenerateDataKey*", "kms:Describe*"
    ]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["logs.amazonaws.com"]
    }
    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:${var.current_partition}:logs:*:${var.current_account_id}:*"]
    }
  }

  statement {
    sid       = "AllowSNSServiceUse"
    effect    = "Allow"
    actions   = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.current_account_id]
    }
  }

  statement {
    sid       = "AllowCloudWatchAndBudgetsToUseKMS"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey*"]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com", "budgets.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.current_account_id]
    }
  }
}

# Attach policy to the CloudWatch KMS Key
resource "aws_kms_key_policy" "cloudwatch" {
  key_id = var.kms_key_cloudwatch_id
  policy = data.aws_iam_policy_document.kms_cloudwatch_policy.json
}
