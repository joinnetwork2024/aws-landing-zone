resource "aviatrix_account" "aws_account" {
  account_name       = var.account_name  # e.g., "dev-account"
  cloud_type         = 1  # AWS
  aws_account_number = var.aws_account_number
  aws_iam            = true  # Use IAM roles for access
  aws_role_app       = "arn:aws:iam::${var.aws_account_number}:role/aviatrix-role-app"
  aws_role_ec2       = "arn:aws:iam::${var.aws_account_number}:role/aviatrix-role-ec2"
}

module "gateway" {
  source = "../../../modules/vpc"
  # Pass the variables required by your module
  vpc_id = "10.30.0.0/16"
  env    = "prd"
}

module "mc_gateway" {
  source  = "terraform-aviatrix-modules/mc-gateway/aviatrix"
  version = "~> 1.7.0"  # Latest compatible

  cloud            = "AWS"
  name             = "${var.gateway_name}-avaitrix-vm"  # e.g., "transit-gateway-uk"
  region           = "eu-west-2"  # Align with project residency
  cidr             = var.cidr  # e.g., "10.1.0.0/16" – Ensure no overlap
  account_name     = aviatrix_account.aws_account.account_name
  gw_size          = "c5.xlarge"  # For transit; adjust for performance
  enable_ha        = true  # High availability
  insane_mode      = true  # High-performance encryption
  subnet           = module.gateway.public_subnets  # If using existing VPC
  use_existing_vpc = true
  vpc_id           = module.gaateway.vpc_id  # From landing zone networking module
}