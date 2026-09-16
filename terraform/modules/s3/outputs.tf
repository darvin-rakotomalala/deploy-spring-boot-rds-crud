############################################
# S3 - OUTPUTS
############################################

output "alb_logs_bucket_name" {
  description = "Name of the S3 bucket storing ALB access logs"
  value       = aws_s3_bucket.alb_logs.id
}

output "alb_logs_bucket_arn" {
  description = "ARN of the S3 bucket storing ALB access logs"
  value       = aws_s3_bucket.alb_logs.arn
}

output "jar_bucket_name" {
  description = "Name of the S3 bucket storing the Spring Boot JAR artifact"
  value       = aws_s3_bucket.jar_artifacts.id
}

output "jar_bucket_arn" {
  description = "ARN of the S3 bucket storing the Spring Boot JAR artifact"
  value       = aws_s3_bucket.jar_artifacts.arn
}

output "bucket_policy_alb_logs" {
  description = "ARN of the S3 bucket storing the Spring Boot JAR artifact"
  value       = aws_s3_bucket_policy.alb_logs.id
}
