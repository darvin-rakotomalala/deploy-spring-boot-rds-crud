############################################
# EC2 Application Tier Server(s) in Private Subnets
############################################

resource "aws_instance" "app" {
  count = var.ec2_instance_count

  ami                    = var.data_aws_ami_ubuntu_id
  instance_type          = var.ec2_instance_type
  subnet_id              = var.app_subnet_ids[count.index % length(var.app_subnet_ids)]
  vpc_security_group_ids = [var.app_security_group_id]
  iam_instance_profile   = var.ec2_app_instance_profile_name

  # Enable detailed (1-minute) CloudWatch monitoring
  monitoring = true

  metadata_options {
    http_tokens                 = "required" # IMDSv2 only
    http_put_response_hop_limit = 1
    http_endpoint               = "enabled"
  }

  root_block_device {
    volume_size           = var.ec2_root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data                   = file("${path.module}/user_data.sh")
  user_data_replace_on_change = true

  tags = merge(var.common_tags, {
    Name = var.ec2_instance_count > 1 ? "spring-boot-server-${var.availability_zones[count.index % length(var.availability_zones)]}" : "spring-boot-server"
  })

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    var.db_credentials_secret_arn,
    var.aws_db_instance_main,
    var.jar_bucket_name,
  ]
}
