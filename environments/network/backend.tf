# environments/networking/main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Define provider aliases for each account
# These credentials would come from your TF_VARs or other secure methods
provider "aws" {
  profile = "network"
  alias   = "networking_account"
  region  = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# Common locals for this environment

locals {
  # Define a map for your common tags
  common_tags = {
    Name        = "terraform"
    ManagedBy   = "Terraform"
    Environment = "PRD-Netowrk" # Example of another common tag
    Project     = var.project_prefix
  }

  # Define VPC CIDRs for networking account here or in variables
  networking_vpc_cidr         = "10.100.0.0/16"
  networking_public_subnets   = ["10.100.0.0/24", "10.100.1.0/24"]
  networking_private_subnets  = ["10.100.10.0/24", "10.100.11.0/24"]
  networking_database_subnets = ["10.100.20.0/24", "10.100.21.0/24"]
  azs                         = ["${var.aws_region}a", "${var.aws_region}b"]
}

#