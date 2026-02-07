module "data_scientist_iam" {
  source = "../modules/iam-least-privilege"

  role_name            = "data-scientist"
  allowed_services     = ["s3", "cloudwatch", "sagemaker"]  # notebooks + data + logging
  environment          = "dev"
  resource_tags        = local.common_tags
  trusted_principal_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]  # or your SSO ARN
}