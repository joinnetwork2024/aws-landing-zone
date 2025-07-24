
# Create the Networking VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 4.0.0"
  providers = {
    aws = aws.networking_account # Use the networking account provider
  }

  name               = "${var.project_prefix}-Networking-VPC"
  cidr         = local.networking_vpc_cidr
  public_subnets    = local.networking_public_subnets
  private_subnets   = local.networking_private_subnets
  
  azs     = local.azs
  enable_nat_gateway     = true # Central TGW reduces need for many NATs
  enable_vpn_gateway       = false

}

# # Create the Transit Gateway
# module "transit_gateway" {
#   source  = "terraform-aws-modules/transit-gateway/aws" # Relative path to your TGW module
#   version = "2.13.0"
#   providers = {
#     aws = aws.networking_account # Use the networking account provider
#   }


#   name            = var.project_prefix
#   description     = "My TGW shared with several other AWS accounts"
#   amazon_side_asn = 64532

#   transit_gateway_cidr_blocks = ["10.99.0.0/24"]

#   # When "true" there is no need for RAM resources if using multiple AWS accounts
#   enable_auto_accept_shared_attachments = true

#   # When "true", SG referencing support is enabled at the Transit Gateway level
#   enable_sg_referencing_support = false

#   # When "true", allows service discovery through IGMP
#   enable_multicast_support = true
# #   project_prefix  = var.project_prefix
# #   amazon_side_asn = "64512" # Example, ensure it's unique
# #   account_ids_to_share_with = [
# #     var.dev_account_id,
# #     var.prod_account_id,
# #     var.security_account_id # Include security account if it needs TGW access
# #   ]

#   # Optionally, you can define initial attachments here, or manage them in dev/prod environments
#   # vpc_attachments = {
#   #   "networking-vpc" = {
#   #     vpc_id     = module.networking_vpc.vpc_id
#   #     subnet_ids = module.networking_vpc.private_subnet_ids # Attach from private subnets
#   #   }
#   # }
# }

