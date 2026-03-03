package terraform.security

import future.keywords.in
import rego.v1

# Policy 1: All new or updated AWS accounts MUST have a 'workload-type' tag
deny contains msg if {
  change := input.resource_changes[_]
  change.type == "aws_organizations_account"
  change.change.actions[_] in {"create", "update"}
  
  # Handle both known tags and unknown (for data sources)
  tags := object.union(change.change.after.tags, change.change.after_unknown.tags)
  
  not tags["workload-type"]
  
  msg := sprintf("Account '%s' must have required tag 'workload-type' for AI/ML governance and isolation (e.g., 'sandbox', 'training', 'inference-prod')", [change.address])
}

# Policy 2: 'workload-type' tag must be an allowed value
allowed_workloads := {"sandbox", "data-science", "training", "registry", "inference-prod"}

deny contains msg if {
  change := input.resource_changes[_]
  change.type == "aws_organizations_account"
  change.change.actions[_] in {"create", "update"}
  
  tags := object.union(change.change.after.tags, change.change.after_unknown.tags)
  workload := tags["workload-type"]
  
  workload
  not workload in allowed_workloads
  
  msg := sprintf("Invalid 'workload-type' value '%s' on account '%s'. Allowed values: %v", [workload, change.address, allowed_workloads])
}