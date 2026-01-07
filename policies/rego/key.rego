package terraform.security

import input as tfplan
import rego.v1

deny contains msg if {
    # 1. Loop through all resources in the plan
    some resource in tfplan.resource_changes
    
    # 2. Filter: Only look at KMS Keys
    resource.type == "aws_kms_key"
    
    # 3. Filter: Only look at managed resources being created or updated
    resource.mode == "managed"
    actions := resource.change.actions
    not count([a | a := actions[_]; a == "delete"]) > 0

    # 4. Check the specific attribute: enable_key_rotation
    # In Terraform, this should be set to true
    rotation_enabled := object.get(resource.change.after, "enable_key_rotation", false)
    rotation_enabled == false

    msg := sprintf("KMS Key '%s' must have 'enable_key_rotation' set to true.", [resource.address])
}