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


resource "aws_organizations_policy_attachment" "workloads_region_restriction" {
  policy_id = aws_organizations_policy.restrict_regions_scp.id
  target_id = aws_organizations_organizational_unit.workloads_ou.id
}


resource "aws_organizations_policy" "baseline_security_guardrails" {
  name        = "baseline-security-guardrails"
  description = "Prevents disabling core security services"
  content     = file("${path.module}/policies/baseline-security-guardrails.json")
  type        = "SERVICE_CONTROL_POLICY"
}

resource "aws_organizations_policy_attachment" "baseline_workloads" {
  policy_id = aws_organizations_policy.baseline_security_guardrails.id
  target_id = aws_organizations_organizational_unit.workloads_ou.id
}


resource "aws_organizations_policy" "root_security_guardrails" {
  name        = "Root-Security-Guardrails"
  description = "Protects organization integrity and auditability"
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("${path.module}/policies/root-security-guardrails.json")
}

resource "aws_organizations_policy_attachment" "root_security_guardrails" {
  policy_id = aws_organizations_policy.root_security_guardrails.id
  target_id = aws_organizations_organization.main.roots[0].id
}
