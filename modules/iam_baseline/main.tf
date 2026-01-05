resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 14
  require_symbols                = true
  require_numbers                = true
  password_reuse_prevention      = 24
  max_password_age               = 90
}

# Role for centralized security team to assume into this account
resource "aws_iam_role" "security_audit" {
  name = "SecurityAuditRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { AWS = "arn:aws:iam::${var.security_account_id}:root" }
    }]
  })
}