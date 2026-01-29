locals {
  # Mandatory Enterprise Tags
  common_tags = {
    CostCenter  = "Infrastructure-101"
    Environment = "prod"
    Owner       = "Platform-Team"
    Project     = "Landing"
  }

  # Helper for Account tags (merges base tags with the specific account name)
  account_tags_dev      = merge(local.common_tags, { Name = "joinnetwork-dev", Environment = "Development" })
  account_tags_prod     = merge(local.common_tags, { Name = "joinnetwork-prod", Environment = "Production" })
  account_tags_staging  = merge(local.common_tags, { Name = "joinnetwork-staging", Environment = "Staging" })
  account_tags_log      = merge(local.common_tags, { Name = "joinnetwork-log", Environment = "Log", Owner = "security-team" })
  account_tags_network  = merge(local.common_tags, { Name = "joinnetwork-network", Environment = "network", Owner = "network-team" })
  account_tags_security = merge(local.common_tags, { Name = "joinnetwork-security", Environment = "security", Owner = "security-team" })
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
  tags      = local.account_tags_log
}

resource "aws_organizations_account" "network" {
  name      = "lz-network"
  email     = var.network_account_email
  parent_id = aws_organizations_organizational_unit.network_ou.id
  tags      = local.account_tags_network
}

# Workload Accounts
resource "aws_organizations_account" "dev" {
  name      = "lz-dev-workload"
  email     = var.dev_account_email
  parent_id = aws_organizations_organizational_unit.workloads_ou.id
  tags      = local.account_tags_dev
}

resource "aws_organizations_account" "staging" {
  name      = "lz-staging-workload"
  email     = var.staging_account_email # Add this to your variables.tf
  parent_id = aws_organizations_organizational_unit.workloads_ou.id
  tags      = local.account_tags_staging
}

resource "aws_organizations_account" "prod" {
  name      = "lz-prod-workload"
  email     = var.prod_account_email # Add this to your variables.tf
  parent_id = aws_organizations_organizational_unit.workloads_ou.id
  tags      = local.account_tags_prod
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