package terraform.security

import input as tfplan
import rego.v1

deny contains violation if {
    some resource in tfplan.resource_changes
    resource.type == "aws_kms_key"
    
    # Filter: Only look at managed resources being created/updated
    resource.mode == "managed"
    actions := resource.change.actions
    not "delete" in actions

    # Logic: rotation must be true
    rotation_enabled := object.get(resource.change.after, "enable_key_rotation", false)
    rotation_enabled == false

    # Structured response including Policy Name
    violation := {
        "policy": "key.rego",
        "address": resource.address,
        "msg": sprintf("KMS Key '%s' must have 'enable_key_rotation' set to true.", [resource.address])
    }
}