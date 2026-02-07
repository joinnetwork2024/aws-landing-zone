package terraform.security

import input as tfplan
import rego.v1

# Helper to find if a bucket has an associated encryption resource
# Helper to find if a bucket has an associated encryption resource
bucket_address_has_encryption(address) if {
    # 1. Walk through the entire configuration to find encryption resources
    some path, value
    walk(tfplan.configuration, [path, value])
    value.type == "aws_s3_bucket_server_side_encryption_configuration"

    # 2. Extract the bucket reference (e.g., aws_s3_bucket.log_bucket)
    some ref in value.expressions.bucket.references
    
    # 3. Clean the address and reference of any indexes like [0] or [1]
    # This ensures "aws_s3_bucket.log_bucket[0]" matches "aws_s3_bucket.log_bucket"
    clean_address := regex.replace(address, `\[\d+\]`, "")
    clean_ref := regex.replace(ref, `\[\d+\]`, "")
    
    # 4. Universal Matching Logic:
    # ROOT: Match if they are exactly the same
    # MODULE: Match if the address ends with ".<reference>"
    match_address_to_ref(clean_address, clean_ref)
}

# Match for root resources (exact match)
match_address_to_ref(addr, ref) if addr == ref

# Match for module resources (suffix match with a dot separator)
match_address_to_ref(addr, ref) if endswith(addr, concat(".", ["", ref]))

# Rule to deny unencrypted buckets
deny contains msg if {
    some bucket in tfplan.resource_changes
    bucket.type == "aws_s3_bucket"

    # Ignore deletions
    not "delete" in bucket.change.actions

    # Check for encryption resource
    not bucket_address_has_encryption(bucket.address)

    # Check for legacy inline encryption for safety
    inline_enc := object.get(bucket.change.after, "server_side_encryption_configuration", [])
    count(inline_enc) == 0

    msg := sprintf("S3 bucket '%s' must have encryption enabled via aws_s3_bucket_server_side_encryption_configuration.", [bucket.address])
}