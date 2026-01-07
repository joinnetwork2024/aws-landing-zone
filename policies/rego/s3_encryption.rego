package terraform.security

import input as tfplan
import rego.v1

# Helper function (must use 'if')
bucket_address_has_encryption(address) if {
    some resource in tfplan.configuration.root_module.resources
    resource.type == "aws_s3_bucket_server_side_encryption_configuration"
    resource.expressions.bucket.references[_] == address
}

# Rule (must use 'contains msg if')
deny contains msg if {
    some bucket in tfplan.resource_changes
    bucket.type == "aws_s3_bucket"

    # Ignore deletions
    actions := bucket.change.actions
    not count([a | a := actions[_]; a == "delete"]) > 0

    # Logic
    not bucket_address_has_encryption(bucket.address)
    inline_enc := object.get(bucket.change.after, "server_side_encryption_configuration", [])
    count(inline_enc) == 0

    msg := sprintf("S3 bucket '%s' must have encryption enabled.", [bucket.address])
}