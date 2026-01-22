
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }

    awscc = {
      source  = "hashicorp/awscc"
      version = "~> 1.0"
    }
  }
}

locals {
  mandatory_tags = {
    CostCenter  = "CC-12345"
    Environment = var.env
    Owner       = "SmartCity Team"
    Project     = "Traffic Management"
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = local.mandatory_tags
  }
}

provider "awscc" {
  region = var.aws_region
}