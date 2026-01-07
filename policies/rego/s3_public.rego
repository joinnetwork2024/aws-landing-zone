package terraform.security

import input as tfplan
import rego.v1

deny contains msg if {
    some resource in tfplan.resource_changes
    resource.type == "aws_s3_bucket_public_access_block"
    
    # Ensure all four privacy settings are set to true
    settings := ["block_public_acls", "block_public_policy", "ignore_public_acls", "restrict_public_buckets"]
    some setting in settings
    resource.change.after[setting] != true

    msg := sprintf("S3 Public Access Block '%s' must have %s set to true.", [resource.address, setting])
}