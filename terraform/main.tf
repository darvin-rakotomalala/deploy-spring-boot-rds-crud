#########################################################
## VPC
#########################################################

module "vpc" {
  source             = "./modules/vpc"
  common_tags        = local.common_tags
  naming_prefix      = local.naming_prefix
  availability_zones = var.availability_zones
  single_nat_gateway = var.single_nat_gateway
  vpc_cidr           = var.vpc_cidr
}

#########################################################
## NACLs
#########################################################

module "nacls" {
  source             = "./modules/nacls"
  naming_prefix      = local.naming_prefix
  common_tags        = local.common_tags
  app_port           = var.app_port
  app_subnet_ids     = module.vpc.app_subnet_ids
  availability_zones = var.availability_zones
  db_subnet_ids      = module.vpc.db_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  vpc_cidr           = var.vpc_cidr
  vpc_id             = module.vpc.vpc_id
}

#########################################################
## SECURITY GROUPS
#########################################################

module "security-groups" {
  source        = "./modules/security-groups"
  common_tags   = local.common_tags
  naming_prefix = local.naming_prefix
  vpc_id        = module.vpc.vpc_id
  app_port      = var.app_port
  db_port       = var.db_port
}

#########################################################
## VPC ENDPOINTS
#########################################################

module "vpc_endpoints" {
  source                          = "./modules/vpc_endpoints"
  naming_prefix                   = local.naming_prefix
  common_tags                     = local.common_tags
  app_subnet_ids                  = module.vpc.app_subnet_ids
  current_account_id              = data.aws_caller_identity.current.account_id
  primary_region                  = var.primary_region
  ssm_endpoints_security_group_id = module.security-groups.ssm_endpoints_security_group_id
  vpc_id                          = module.vpc.vpc_id
}

#########################################################
## IAM
#########################################################

module "iam" {
  source                            = "./modules/iam"
  current_account_id                = data.aws_caller_identity.current.account_id
  naming_prefix                     = local.naming_prefix
  common_tags                       = local.common_tags
  github_org                        = var.github_org
  github_repo                       = var.github_repo
  current_partition                 = data.aws_partition.current.partition
  jar_bucket_name                   = var.jar_bucket_name
  kms_key_cloudwatch_arn            = module.kms.kms_cloudwatch_key_arn
  kms_key_cloudwatch_id             = module.kms.kms_cloudwatch_key_id
  kms_key_rds_arn                   = module.kms.kms_rds_key_arn
  kms_key_secrets_arn               = module.kms.kms_secrets_key_arn
  log_group_app_tier_arn            = module.cloudwatch.app_tier_log_group_arn
  primary_region                    = var.primary_region
  secretsmanager_db_credentials_arn = module.secrets-manager.db_credentials_secret_arn
  ec2_instance_ids                  = module.ec2.ec2_instance_ids
}

#########################################################
## KMS
#########################################################

module "kms" {
  source                           = "./modules/kms"
  naming_prefix                    = local.naming_prefix
  common_tags                      = local.common_tags
  current_account_id               = data.aws_caller_identity.current.account_id
  current_partition                = data.aws_partition.current.partition
  iam_role_ec2_app_arn             = module.iam.ec2_app_role_arn
  iam_role_terraform_execution_arn = module.iam.iam_role_terraform_execution_arn
}

#########################################################
## S3
#########################################################

module "s3" {
  source                           = "./modules/s3"
  naming_prefix                    = local.naming_prefix
  common_tags                      = local.common_tags
  alb_logs_bucket_name             = var.alb_logs_bucket_name
  current_account_id               = data.aws_caller_identity.current.account_id
  iam_role_ec2_app_arn             = module.iam.ec2_app_role_arn
  jar_bucket_name                  = var.jar_bucket_name
  kms_key_alb_logs_arn             = module.kms.kms_key_alb_logs_arn
  kms_key_jar_artifacts_arn        = module.kms.kms_key_jar_artifacts_arn
  iam_role_terraform_execution_arn = module.iam.iam_role_terraform_execution_arn
}

#########################################################
## GATEWAY ENDPOINT FOR S3
#########################################################

module "gateway-endpoint" {
  source                   = "./modules/gateway-endpoint"
  naming_prefix            = local.naming_prefix
  common_tags              = local.common_tags
  app_route_table_ids      = module.vpc.app_route_table_ids
  bucket_alb_logs_arn      = module.s3.alb_logs_bucket_arn
  bucket_jar_artifacts_arn = module.s3.jar_bucket_arn
  primary_region           = var.primary_region
  vpc_id                   = module.vpc.vpc_id
}

#########################################################
## RDS
#########################################################

module "rds" {
  source                           = "./modules/rds"
  naming_prefix                    = local.naming_prefix
  common_tags                      = local.common_tags
  identifier                       = local.rds_identifier
  db_allocated_storage             = var.db_allocated_storage
  db_backup_retention_days         = var.db_backup_retention_days
  db_engine_version                = var.db_engine_version
  db_instance_class                = var.db_instance_class
  db_max_allocated_storage         = var.db_max_allocated_storage
  db_multi_az                      = var.db_multi_az
  db_name                          = var.db_name
  db_subnet_group_name             = module.vpc.db_subnet_group_name
  db_username                      = var.db_username
  ec2_instance_ids                 = module.ec2.ec2_instance_ids
  environment                      = var.environment
  kms_rds_key_arn                  = module.kms.kms_rds_key_arn
  random_password_db_master_result = module.secrets-manager.random_password_db_master_result
  rds_enhanced_monitoring_role_arn = module.iam.rds_enhanced_monitoring_role_arn
  rds_log_group_name               = module.cloudwatch.rds_log_group_name
  rds_security_group_id            = module.security-groups.rds_security_group_id
  primary_region                   = var.primary_region
}

#########################################################
## SECRETS MANAGER
#########################################################

module "secrets-manager" {
  source              = "./modules/secrets-manager"
  naming_prefix       = local.naming_prefix
  common_tags         = local.common_tags
  db_name             = var.db_name
  db_username         = var.db_username
  kms_secrets_key_arn = module.kms.kms_secrets_key_arn
  rds_address         = module.rds.rds_address
  rds_port            = module.rds.rds_port
}

#########################################################
## EC2
#########################################################

module "ec2" {
  source                        = "./modules/ec2"
  naming_prefix                 = local.naming_prefix
  common_tags                   = local.common_tags
  app_port                      = var.app_port
  app_security_group_id         = module.security-groups.app_security_group_id
  app_subnet_ids                = module.vpc.app_subnet_ids
  app_tier_log_group_name       = module.cloudwatch.app_tier_log_group_name
  availability_zones            = var.availability_zones
  aws_db_instance_main          = module.rds.aws_db_instance_main
  data_aws_ami_ubuntu_id        = data.aws_ami.ubuntu.id
  db_credentials_secret_arn     = module.secrets-manager.db_credentials_secret_arn
  ec2_app_instance_profile_name = module.iam.ec2_app_instance_profile_name
  ec2_instance_count            = var.ec2_instance_count
  ec2_instance_type             = var.ec2_instance_type
  ec2_root_volume_size          = var.ec2_root_volume_size
  jar_artifacts_bucket_id       = module.s3.jar_bucket_name
  jar_bucket_name               = module.s3.jar_bucket_name
  jar_file_key                  = var.jar_file_key
  log_retention_days            = var.log_retention_days
  primary_region                = var.primary_region
}

#########################################################
## ALB
#########################################################

module "alb" {
  source                     = "./modules/alb"
  naming_prefix              = local.naming_prefix
  common_tags                = local.common_tags
  acm_certificate_arn        = var.acm_certificate_arn
  alb_logs_bucket_id         = module.s3.alb_logs_bucket_name
  alb_security_group_id      = module.security-groups.alb_security_group_id
  app_port                   = var.app_port
  bucket_policy_alb_logs     = module.s3.bucket_policy_alb_logs
  ec2_instance_count         = var.ec2_instance_count
  ec2_instance_ids           = module.ec2.ec2_instance_ids
  enable_deletion_protection = var.enable_deletion_protection
  health_check_path          = var.health_check_path
  public_subnet_ids          = module.vpc.public_subnet_ids
  vpc_id                     = module.vpc.vpc_id
}

#########################################################
## SNS
#########################################################

module "sns" {
  source                = "./modules/sns"
  naming_prefix         = local.naming_prefix
  common_tags           = local.common_tags
  alert_emails          = var.alert_emails
  current_account_id    = data.aws_caller_identity.current.account_id
  kms_key_cloudwatch_id = module.kms.kms_cloudwatch_key_id
}

#########################################################
## CLOUDWATCH
#########################################################

module "cloudwatch" {
  source                       = "./modules/cloudwatch"
  naming_prefix                = local.naming_prefix
  common_tags                  = local.common_tags
  aws_db_instance_main         = module.rds.aws_db_instance_main
  ec2_instance_ids             = module.ec2.ec2_instance_ids
  kms_cloudwatch_key_arn       = module.kms.kms_cloudwatch_key_arn
  log_retention_days           = var.log_retention_days
  primary_region               = var.primary_region
  rds_identifier               = local.rds_identifier
  sns_alerts_topic_arn         = module.sns.sns_alerts_topic_arn
  db_instance_class            = var.db_instance_class
  connection_threshold_percent = var.connection_threshold_percent
  cpu_threshold_percent        = var.cpu_threshold_percent
}

# Uncomment to test local
# resource "aws_s3_object" "provision_source_files" {
#   bucket   = module.s3.jar_bucket_name
#   for_each = fileset("${var.source_file}/", "**/*.*")
#   key      = each.value
#   source   = "${var.source_file}/${each.value}"
#
#   content_type = lookup(local.mime_types, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")
#
#   # Use source_hash instead of etag when kms_key_id is specified
#   source_hash = filemd5("${var.source_file}/${each.value}")
#   kms_key_id  = module.kms.kms_key_jar_artifacts_arn
# }
