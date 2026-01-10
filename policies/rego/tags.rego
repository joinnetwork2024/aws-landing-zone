package terraform.security

import input as tfplan
import rego.v1

mandatory_tags := {"CostCenter", "Environment", "Owner"}

# Add resources that DO NOT support tags to this set
untaggable_resources := {
    "aws_iam_role_policy",
    "aws_iam_policy_attachment",
    "aws_s3_bucket_policy",
    "aws_s3_bucket_public_access_block",
    "aws_s3_bucket_server_side_encryption_configuration",
    "aws_s3_bucket_versioning",
    "aws_organizations_organization",
    "aws_organizations_policy_attachment",
    "aws_route_table_association",
    "aws_sns_topic_subscription"
}

deny contains msg if {
    some resource in tfplan.resource_changes
    resource.mode == "managed"

    # CRITICAL: Skip the resource if it's in our "untaggable" list
    not untaggable_resources[resource.type]

    # Look for tags in after or tags_all
    after_vals := resource.change.after
    tags := object.get(after_vals, "tags", {})
    tags_all := object.get(after_vals, "tags_all", {})

    missing := [tag | 
        tag := mandatory_tags[_]
        not tags[tag]
        not tags_all[tag]
    ]

    count(missing) > 0
    msg := sprintf("Resource '%s' is missing mandatory tags: %v", [resource.address, missing])
}