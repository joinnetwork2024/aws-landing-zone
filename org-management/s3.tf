resource "aws_kms_key" "s3" {
  description             = "KMS key for Terraform state"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}