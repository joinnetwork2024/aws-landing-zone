locals {
  # Define a map for your common tags
  common_tags = {
    Name        = "terraform"
    ManagedBy   = "Terraform"
    Environment = "LandingZone" # Example of another common tag
    Project     = var.project_prefix
  }
}
# ----------------------------------------------------
# 1. Enable AWS Organizations (if not already enabled)
# ----------------------------------------------------
resource "aws_organizations_organization" "main" {
  feature_set = "ALL" # Enables all features, including Service Control Policies (SCPs)
  # List AWS services that you want to enable trusted access with your organization
  # These are crucial for services like SSO, CloudTrail, Config to function org-wide.
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "sso.amazonaws.com",
    # "organizations.amazonaws.com", # Added for newer versions, implicit
    "securityhub.amazonaws.com",
    "guardduty.amazonaws.com",
    "macie.amazonaws.com",
    "fms.amazonaws.com", # Firewall Manager
  ]
  enabled_policy_types = ["SERVICE_CONTROL_POLICY", ]

}

# ----------------------------------------------------
# 1. Data source for existing AWS Organizations (instead of creating)
# ----------------------------------------------------
# data "aws_organizations_organization" "current" {}


# ----------------------------------------------------
# 2. Create Organizational Units (OUs)
# ----------------------------------------------------
resource "aws_organizations_organizational_unit" "security_ou" {
  name      = "SEC"
  parent_id = aws_organizations_organization.main.roots[0].id # Attaches to the Organization Root

  tags = {
    Name = "${var.project_prefix}-SecurityOU"
  }
}

resource "aws_organizations_organizational_unit" "network_ou" {
  name      = "Network"
  parent_id = aws_organizations_organization.main.roots[0].id

  tags = {
    Name = "${var.project_prefix}-NetworkOU"
  }
}

resource "aws_organizations_organizational_unit" "dev_ou" {
  name      = "Development"
  parent_id = aws_organizations_organization.main.roots[0].id

  tags = {
    Name = "${var.project_prefix}-DevOU"
  }
}

resource "aws_organizations_organizational_unit" "sandbox_ou" {
  name      = "Sandbox"
  parent_id = aws_organizations_organization.main.roots[0].id

  tags = {
    Name = "${var.project_prefix}-SandboxOU"
  }
}

# ----------------------------------------------------
# 3. Create Member Accounts (and place them in OUs)
# NOTE: Each account requires a unique email address.
# AWS will send an invitation to this email.
# ----------------------------------------------------

resource "aws_organizations_account" "audit_account" {
  name      = "sdtrading"    # Friendly name for the account
  email     = var.root_email # !!! REPLACE WITH UNIQUE EMAIL !!!
  parent_id = aws_organizations_organizational_unit.security_ou.id
  #   iam_user_access_to_billing = "ALLOW" # Important for cost management roles

  tags = {
    Name = "${var.project_prefix}-AuditAccount"
  }

  lifecycle {
    # Ignore changes to 'iam_user_access_to_billing'
    # This prevents replacement if this attribute is the only one changing
    # or if the existing account's setting cannot be changed in-place.
    ignore_changes = [
      iam_user_access_to_billing,
      # You might also want to ignore other attributes if they are often
      # managed outside Terraform or if their initial value can't be read back
      # or causes spurious diffs, e.g., 'email' if you only want it set at creation.
      # email,
      # name, # Be careful with ignoring 'name' if you want Terraform to manage renaming
      # parent_id, # Only ignore if you move OUs manually often
    ]
  }
}

resource "aws_organizations_account" "log_archive_account" {
  name                       = "lz-log-archive"
  email                      = var.security_account_email # !!! REPLACE WITH UNIQUE EMAIL !!!
  parent_id                  = aws_organizations_organizational_unit.security_ou.id
  iam_user_access_to_billing = "ALLOW"

  tags = {
    Name = "${var.project_prefix}-LogArchiveAccount"
  }
}

resource "aws_organizations_account" "network_account" {
  name                       = "lz-network"
  email                      = var.network_account_email # !!! REPLACE WITH UNIQUE EMAIL !!!
  parent_id                  = aws_organizations_organizational_unit.network_ou.id
  iam_user_access_to_billing = "ALLOW"

  tags = {
    Name = "${var.project_prefix}-NetworkAccount"
  }
}

resource "aws_organizations_account" "dev_workload_account" {
  name                       = "lz-dev-workload-01"
  email                      = var.dev_account_email # !!! REPLACE WITH UNIQUE EMAIL !!!
  parent_id                  = aws_organizations_organizational_unit.dev_ou.id
  iam_user_access_to_billing = "ALLOW"

  tags = {
    Name = "${var.project_prefix}-DevWorkloadAccount"
  }
}

