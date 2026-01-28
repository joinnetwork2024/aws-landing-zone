# KMS Key
output "cloudtrail_kms_key_id" {
  description = "The ID of the KMS key used for CloudTrail log encryption."
  value       = aws_kms_key.cloudtrail_kms_key.key_id
}

output "cloudtrail_kms_key_arn" {
  description = "The ARN of the KMS key used for CloudTrail log encryption."
  value       = aws_kms_key.cloudtrail_kms_key.arn
}

# CloudTrail
output "cloudtrail_trail_name" {
  description = "The name of the AWS CloudTrail Organization Trail."
  value       = aws_cloudtrail.organization_trail.name
}

output "cloudtrail_trail_arn" {
  description = "The ARN of the AWS CloudTrail Organization Trail."
  value       = aws_cloudtrail.organization_trail.arn
}

# S3 Bucket
output "cloudtrail_s3_bucket_id" {
  description = "The ID (name) of the S3 bucket used for CloudTrail logs."
  value       = aws_s3_bucket.cloudtrail_logs.id
}

output "cloudtrail_s3_bucket_arn" {
  description = "The ARN of the S3 bucket used for CloudTrail logs."
  value       = aws_s3_bucket.cloudtrail_logs.arn
}

# CloudWatch Log Group
output "cloudtrail_log_group_name" {
  description = "The name of the CloudWatch Log Group for CloudTrail logs."
  value       = aws_cloudwatch_log_group.cloudtrail_log_group.name
}

output "cloudtrail_log_group_arn" {
  description = "The ARN of the CloudWatch Log Group for CloudTrail logs."
  value       = aws_cloudwatch_log_group.cloudtrail_log_group.arn
}

# IAM Role for CloudTrail to CloudWatch
output "cloudtrail_cloudwatch_role_name" {
  description = "The name of the IAM role used by CloudTrail to publish to CloudWatch Logs."
  value       = aws_iam_role.cloudtrail_cloudwatch_role.name
}

output "cloudtrail_cloudwatch_role_arn" {
  description = "The ARN of the IAM role used by CloudTrail to publish to CloudWatch Logs."
  value       = aws_iam_role.cloudtrail_cloudwatch_role.arn
}

# AWS Account ID
output "staging_id" {
  description = "The AWS Account ID for the Staging workload"
  value       = aws_organizations_account.staging.id
}

output "dev_id" {
  description = "The AWS Account ID for the Staging workload"
  value       = aws_organizations_account.dev.id
}

output "prod" {
  description = "The AWS Account ID for the Staging workload"
  value       = aws_organizations_account.prod.id
}
