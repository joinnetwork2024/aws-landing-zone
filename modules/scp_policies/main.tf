resource "aws_organizations_policy" "deny_regions" {
  name        = "DenyNonApprovedRegions"
  description = "Restricts resource creation to approved regions only"
  type        = "SERVICE_CONTROL_POLICY"

  content = templatefile("${path.module}/denyregion.json", {
    allowed_regions = jsonencode(var.allowed_regions)  # Renders as ["eu-west-2","eu-central-1"]
  })

  # content = jsonencode({
  #   Version = "2012-10-17"
  #   Statement = [{
  #     Sid      = "DenyAllOutsideApproved"
  #     Effect   = "Deny"
  #     NotAction = [
  #       "iam:*", "organizations:*", "route53:*", "support:*"
  #     ]
  #     Resource = "*"
  #     Condition = {
  #       StringNotEquals = { "aws:RequestedRegion": var.allowed_regions }
  #     }
  #   }]
  # })
}