locals {
  common_tags = {
    ManagedBy   = "Terraform"
    Environment = "LandingZone"
    Project     = var.project_prefix
  }
}

# ----------------------------------------------------
# 1. Enable AWS Organizations
# ----------------------------------------------------
resource "aws_organizations_organization" "main" {
  feature_set = "ALL"
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "sso.amazonaws.com",
    "securityhub.amazonaws.com",
    "guardduty.amazonaws.com",
    "macie.amazonaws.com",
    "fms.amazonaws.com",
  ]
  enabled_policy_types = ["SERVICE_CONTROL_POLICY"]
}

# ----------------------------------------------------
# 2. Organizational Units (OUs) - Adding "Workloads" OU
# ----------------------------------------------------
resource "aws_organizations_organizational_unit" "security_ou" {
  name      = "SEC"
  parent_id = aws_organizations_organization.main.roots[0].id
}

resource "aws_organizations_organizational_unit" "network_ou" {
  name      = "Network"
  parent_id = aws_organizations_organization.main.roots[0].id
}

# New: Workload OU to house Dev, Staging, and Prod
resource "aws_organizations_organizational_unit" "workloads_ou" {
  name      = "Workloads"
  parent_id = aws_organizations_organization.main.roots[0].id
}

# ----------------------------------------------------
# 3. Member Accounts (Dev, Staging, Prod)
# ----------------------------------------------------

# Shared Infrastructure Accounts (Security & Network)
resource "aws_organizations_account" "log_archive" {
  name      = "lz-log-archive"
  email     = var.log_archive_email
  parent_id = aws_organizations_organizational_unit.security_ou.id
}

resource "aws_organizations_account" "network" {
  name      = "lz-network"
  email     = var.network_account_email
  parent_id = aws_organizations_organizational_unit.network_ou.id
}

# Workload Accounts
resource "aws_organizations_account" "dev" {
  name      = "lz-dev-workload"
  email     = var.dev_account_email
  parent_id = aws_organizations_organizational_unit.workloads_ou.id
}

resource "aws_organizations_account" "staging" {
  name      = "lz-staging-workload"
  email     = var.staging_account_email # Add this to your variables.tf
  parent_id = aws_organizations_organizational_unit.workloads_ou.id
}

resource "aws_organizations_account" "prod" {
  name      = "lz-prod-workload"
  email     = var.prod_account_email # Add this to your variables.tf
  parent_id = aws_organizations_organizational_unit.workloads_ou.id
}

# ----------------------------------------------------
# 4. Applying SCP Module (The Security Guardrails)
# ----------------------------------------------------
module "scp_guardrails" {
  source = "../modules/scp_policies"

  # Pass variables required by your module
  allowed_regions = ["us-east-1", "us-west-2"]

  # You can target the entire Root or specific OUs
  target_id = aws_organizations_organization.main.roots[0].id
}