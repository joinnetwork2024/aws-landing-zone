# 1. KMS Key for Encrypting Logs
resource "aws_kms_key" "cloudtrail_kms_key" {
  description             = "KMS key for CloudTrail organization logs"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = templatefile("${path.module}/policies/kms-key.json", {
    # Using the ID of the Log Archive account we created in main.tf
    log_archive_account_id = aws_organizations_account.log_archive.id,
    trail_name             = "${var.project_prefix}-Organization-Trail"
  })
  tags = local.common_tags
}

# 2. S3 Bucket for Logs (Dedicated to CloudTrail)
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "${var.project_prefix}-org-logs-${aws_organizations_account.log_archive.id}"

  # Modern Object Ownership
  force_destroy = false
  tags = local.common_tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
  }
}

# 3. Bucket Policy (Allows all accounts in Org to write logs)
resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  policy = templatefile("${path.module}/policies/s3-cloudtrail-bucket-policy.json", {
    cloudtrail_logs_bucket_arn = aws_s3_bucket.cloudtrail_logs.arn,
    log_archive_account_id     = aws_organizations_account.log_archive.id
  })
}

# 4. The Organization Trail
resource "aws_cloudtrail" "organization_trail" {
  name                          = "${var.project_prefix}-Organization-Trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  is_organization_trail         = true
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.cloudtrail_kms_key.arn

  # CloudWatch Integration
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail_log_group.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cloudwatch_role.arn
  tags = local.common_tags

  depends_on = [aws_s3_bucket_policy.cloudtrail_bucket_policy]
}

# 5. CloudWatch Log Group
resource "aws_cloudwatch_log_group" "cloudtrail_log_group" {
  name              = "/aws/cloudtrail/${var.project_prefix}-Org-Trail"
  retention_in_days = 365
}

# This is the resource that Terraform says is missing
resource "aws_iam_role" "cloudtrail_cloudwatch_role" {
  name = "${var.project_prefix}-CloudTrail-CloudWatch-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      }
    ]
  })
}

# You also need the policy so CloudTrail can actually write to the logs
resource "aws_iam_role_policy" "cloudtrail_cloudwatch_policy" {
  name = "${var.project_prefix}-CloudTrail-CloudWatch-Policy"
  role = aws_iam_role.cloudtrail_cloudwatch_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailCreateLogStream"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail_log_group.arn}:*"
      }
    ]
  })
 
}