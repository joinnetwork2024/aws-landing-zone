package terraform.security

import input as tfplan

# Deny if an S3 bucket is created without server-side encryption
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    
    # Check if encryption is missing
    not resource.change.after.server_side_encryption_configuration
    
    msg := sprintf("S3 bucket '%s' must have encryption enabled.", [resource.address])
}