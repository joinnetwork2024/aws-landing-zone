
data "aws_caller_identity" "current" {}

# Step 1: Enable Security Hub in management account (auto-enables members with org config)
resource "aws_securityhub_account" "org_main" {}

# Step 2: Self-delegate as org admin (quick path – management account)
resource "aws_securityhub_organization_admin_account" "org_self" {
  admin_account_id = data.aws_caller_identity.current.account_id

  depends_on = [aws_securityhub_account.org_main]
}

# Step 3: Org-wide configuration (auto-enable new/future AI/ML accounts)
resource "aws_securityhub_organization_configuration" "org_main" {
  auto_enable = true

  depends_on = [aws_securityhub_organization_admin_account.org_self]
}

# Step 4: Subscribe to AFSBP (region-specific ARN)
resource "aws_securityhub_standards_subscription" "afsbp" {
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"

  depends_on = [
    aws_securityhub_account.org_main,
    aws_securityhub_organization_configuration.org_main
  ]
}