# ----------------------------------------------------
# Service Control Policies (SCPs)
# ----------------------------------------------------

# data "aws_organizations_organization" "this" {}

# resource "aws_organizations_policy_type" "scp" {
#   root_id     = data.aws_organizations_organization.this.roots[0].id
#   policy_type = "SERVICE_CONTROL_POLICY"
# }

# Data source for the existing Organization root ID
# Needed if you're not creating the organization in the same Terraform run
data "aws_organizations_organization" "current" {}

# Data sources for your Organizational Unit IDs
# REPLACE THESE WITH YOUR ACTUAL OU IDs or reference from outputs if created by Terraform
data "aws_organizations_organizational_unit" "security_ou" {
  name      = "Security"
  parent_id = data.aws_organizations_organization.current.roots[0].id # Assumes Security OU is directly under root
}
data "aws_organizations_organizational_unit" "network_ou" {
  name      = "Network"
  parent_id = data.aws_organizations_organization.current.roots[0].id # Assumes Network OU is directly under root
}
data "aws_organizations_organizational_unit" "development_ou" {
  name      = "Development"
  parent_id = data.aws_organizations_organization.current.roots[0].id # Assumes Development OU is directly under root
}
data "aws_organizations_organizational_unit" "sandbox_ou" {
  name      = "Sandbox"
  parent_id = data.aws_organizations_organization.current.roots[0].id # Assumes Sandbox OU is directly under root
}



# SCP: Deny actions outside specified regions (REVISED with file loading)
resource "aws_organizations_policy" "restrict_regions_scp" {
  name        = "${var.project_prefix}-Restrict-Regions-SCP"
  description = "Denies actions in regions not explicitly allowed, except for global services."
  type        = "SERVICE_CONTROL_POLICY"
  content = templatefile("${path.module}/policies/scp-restrict-regions.json", {
    allowed_regions = jsonencode(var.allowed_regions)
  })
  tags = {
    Name = "${var.project_prefix}-RestrictRegionsSCP"
  }
}

# Attach SCP to OUs 
resource "aws_organizations_policy_attachment" "restrict_regions_dev_attachment" {
  depends_on = [aws_organizations_organization.main]
  policy_id  = aws_organizations_policy.restrict_regions_scp.id
  target_id  = data.aws_organizations_organizational_unit.development_ou.id
}

resource "aws_organizations_policy_attachment" "restrict_regions_net_attachment" {
  depends_on = [aws_organizations_organization.main]
  policy_id  = aws_organizations_policy.restrict_regions_scp.id
  target_id  = data.aws_organizations_organizational_unit.network_ou.id
}
# ... other SCP attachments ...

resource "aws_organizations_policy" "baseline_deny_all" {
  name        = "Baseline-Deny-All"
  description = "Denies all actions unless explicitly allowed"
  content     = file("${path.module}/policies/baseline-deny-all.json")
  type        = "SERVICE_CONTROL_POLICY"
    tags = {
    Name = "${var.project_prefix}-AuditAccount"
  }
}

resource "aws_organizations_policy_attachment" "deny_all_network" {
  depends_on = [aws_organizations_organization.main]
  policy_id  = aws_organizations_policy.baseline_deny_all.id
  target_id  = data.aws_organizations_organizational_unit.network_ou.id
}

resource "aws_organizations_policy_attachment" "deny_all_development" {
  depends_on = [aws_organizations_organization.main]
  policy_id  = aws_organizations_policy.baseline_deny_all.id
  target_id  = data.aws_organizations_organizational_unit.development_ou.id
}
