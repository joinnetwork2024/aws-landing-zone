provider "aws" {
  region     = "eu-west-2"
  assume_role {
    role_arn = "arn:aws:iam::${var.dev_account_id}:role/OrganizationAccountAccessRole"  # Created automatically by Organizations
  }
}

# Example resources: VPC for dev
resource "aws_vpc" "dev_vpc" {
  cidr_block = "10.120.0.0/16"
  tags = { Name = "staging-vpc" }
}

