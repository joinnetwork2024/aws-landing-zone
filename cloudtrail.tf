# ----------------------------------------------------
# Centralized CloudTrail Configuration
# This module should be deployed from the Management Account assuming a role
# into the Log Archive Account (var.log_archive_account_id).
# ----------------------------------------------------

# (Optional) KMS Key for CloudTrail Log Encryption
resource "aws_kms_key" "cloudtrail_kms_key" {
  description             = "${var.project_prefix}-cloudtrail-encryption-key"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = templatefile("${path.module}/policies/kms-key.json", {
    log_archive_account_id = var.log_archive_account_id,
    trail_name              = "${var.project_prefix}-Organization-Trail"
  })
}

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
      
#       {
#         Sid       = "Enable CloudTrail IAM User Permissions"
#         Effect    = "Allow",
#         # Ensure the Management Account (or the deploying principal) can manage this key
#         Principal = {
#           AWS = "arn:aws:iam::${var.log_archive_account_id}:root" # Assuming management account ID is a variable
#         },
#         Action    = "kms:*",
#         Resource  = "*"
#       },
#       {
#         Sid       = "Allow CloudTrail to Encrypt Logs"
#         Effect    = "Allow",
#         Principal = {
#           Service = "cloudtrail.amazonaws.com"
#         },
#         Action    = [
#           "kms:GenerateDataKey*",
#           "kms:Decrypt"
#         ],
#         Resource  = "*",
#         Condition = {
#           StringEquals = {
#             "kms:EncryptionContext:aws:cloudtrail:arn" : "arn:aws:cloudtrail:*:${var.log_archive_account_id}:trail/*"
#           }
#         }
#       },
#       {
#         Sid       = "Allow CloudTrail Log Delivery"
#         Effect    = "Allow",
#         Principal = {
#           Service = "s3.amazonaws.com" # For CloudTrail S3 access
#         },
#         Action    = "kms:Decrypt",
#         Resource  = "*",
#         Condition = {
#           StringEquals = {
#             "kms:EncryptionContext:aws:s3:arn" : [
#               "arn:aws:s3:::${aws_s3_bucket.tf_state.id}/AWSLogs/${var.log_archive_account_id}/*",
#               "arn:aws:s3:::${aws_s3_bucket.tf_state.id}/AWSLogs/o-*" # For organization logs
#             ]
#           }
#         }
#       }
#     ]
#   })
# }

# S3 Bucket for CloudTrail Logs
# This bucket must be in the Log Archive account.
# resource "aws_s3_bucket" "cloudtrail_logs" {
#   bucket = "${var.project_prefix}-cloudtrail-logs-${var.log_archive_account_id}" # Naming convention for uniqueness
#   # Using `object_ownership` and `control_object_ownership` is the modern approach
#   # instead of `acl` for new buckets.
#   # The ACL will be applied implicitly by CloudTrail delivery if policies allow.
#   object_ownership = "BucketOwnerPreferred"

#   versioning {
#     enabled = true # Recommended for audit logs
#   }

#   server_side_encryption_configuration {
#     rule {
#       apply_server_side_encryption_by_default {
#         kms_master_key_id = aws_kms_key.cloudtrail_kms_key.arn # Encrypt with KMS
#         sse_algorithm     = "aws:kms"
#       }
#     }
#   }

#   lifecycle_rule {
#     id      = "expire-old-logs"
#     enabled = true
#     # Adjust retention as per your compliance requirements
#     expiration {
#       days = 3650 # Keep logs for 10 years (example)
#     }
#     # Transition to cheaper storage after a period
#     transition {
#       days          = 90
#       storage_class = "GLACIER"
#     }
#   }
# }

# S3 Bucket Policy to allow CloudTrail to write logs
resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.tf_state.id
  policy = templatefile("${path.module}/policies/s3-cloudtrail-bucket-policy.json", {
    cloudtrail_logs_bucket_arn = aws_s3_bucket.tf_state.arn
    log_archive_account_id     = var.log_archive_account_id
  })
}

# AWS CloudTrail Organization Trail
resource "aws_cloudtrail" "organization_trail" {
  name                          = "${var.project_prefix}-Organization-Trail"
  s3_bucket_name                = aws_s3_bucket.tf_state.id
  is_organization_trail         = true # Crucial for collecting logs from all accounts
  include_global_service_events = true # Recommended for comprehensive audit
  enable_log_file_validation    = true # Ensures log integrity
  kms_key_id                    = aws_kms_key.cloudtrail_kms_key.arn # Encrypt logs with KMS

  # Optional: Send logs to CloudWatch Logs for real-time monitoring
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail_log_group.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cloudwatch_role.arn


  # Explicit dependencies to ensure resources are fully provisioned before CloudTrail attempts validation
  depends_on = [
    aws_cloudwatch_log_group.cloudtrail_log_group,
    aws_iam_role.cloudtrail_cloudwatch_role,
    aws_iam_role_policy.cloudtrail_cloudwatch_policy,
    aws_s3_bucket.tf_state,
    aws_s3_bucket_policy.cloudtrail_bucket_policy,
    aws_kms_key.cloudtrail_kms_key
  ]
}

# IAM Role for CloudTrail to send logs to CloudWatch Logs
resource "aws_iam_role" "cloudtrail_cloudwatch_role" {
  name = "${var.project_prefix}-CloudTrail-CloudWatch-Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action    = "sts:AssumeRole"
      }
    ]

  })
        lifecycle {
    # Ignore changes to 'iam_user_access_to_billing'
    # This prevents replacement if this attribute is the only one changing
    # or if the existing account's setting cannot be changed in-place.
    ignore_changes = [
      assume_role_policy,
      # You might also want to ignore other attributes if they are often
      # managed outside Terraform or if their initial value can't be read back
      # or causes spurious diffs, e.g., 'email' if you only want it set at creation.
      # email,
      # name, # Be careful with ignoring 'name' if you want Terraform to manage renaming
      # parent_id, # Only ignore if you move OUs manually often
    ]
  }
}

# IAM Policy for CloudTrail to send logs to CloudWatch Logs
resource "aws_iam_role_policy" "cloudtrail_cloudwatch_policy" {
  name = "${var.project_prefix}-CloudTrail-CloudWatch-Policy"
  role = aws_iam_role.cloudtrail_cloudwatch_role.id
  policy = templatefile("${path.module}/policies/cloudtrail-cloudwatch-role-policy.json", {
    cloudtrail_log_group_arn_with_wildcard = "${aws_cloudwatch_log_group.cloudtrail_log_group.arn}:*"
  })
}

# CloudWatch Logs Group for CloudTrail
resource "aws_cloudwatch_log_group" "cloudtrail_log_group" {
  name              = "/aws/cloudtrail/${var.project_prefix}-Organization-Trail" # Recommended naming
  retention_in_days = 365 # Adjust retention as needed for real-time analysis/alerts
}