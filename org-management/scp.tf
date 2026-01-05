# ----------------------------------------------------
# Service Control Policies (SCPs)
# ----------------------------------------------------

# SCP 1: Restrict Regions (Denies actions outside allowed regions)
resource "aws_organizations_policy" "restrict_regions_scp" {
  name        = "${var.project_prefix}-Restrict-Regions-SCP"
  description = "Denies actions in regions not explicitly allowed, except global services."
  type        = "SERVICE_CONTROL_POLICY"

  # Loading the JSON from your policies folder
  content = templatefile("${path.module}/policies/scp-restrict-regions.json", {
    allowed_regions = jsonencode(var.allowed_regions)
  })
}

# Attach to the Workloads OU (Covers Dev, Staging, and Prod at once)
resource "aws_organizations_policy_attachment" "workloads_region_restriction" {
  policy_id = aws_organizations_policy.restrict_regions_scp.id
  target_id = aws_organizations_organizational_unit.workloads_ou.id
}

# SCP 2: Baseline Deny (Protecting sensitive OUs)
resource "aws_organizations_policy" "baseline_deny_all" {
  name        = "Baseline-Deny-All"
  description = "Denies all actions unless explicitly allowed"
  content     = file("${path.module}/policies/baseline-deny-all.json")
  type        = "SERVICE_CONTROL_POLICY"
}

# Example: Attaching a strict policy to a specific account or OU if needed
# resource "aws_organizations_policy_attachment" "deny_all_security" {
#   policy_id = aws_organizations_policy.baseline_deny_all.id
#   target_id = aws_organizations_organizational_unit.security_ou.id
# }