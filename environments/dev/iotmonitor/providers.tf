# Root main.tf (or a providers.tf file)

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70" # or latest compatible version
    }
  }
}

locals {
  mandatory_tags = {
    CostCenter  = "CC-12345" # ← change to your real value
    Environment = "dev"      # ← or use var.env
    Owner       = "APP Team" # or your name/email
  }
}

provider "aws" {
  region = "eu-west-2" # your region

  default_tags {
    tags = local.mandatory_tags
  }
}

provider "aws" {
  alias  = "eu-west-2"
  region = "eu-west-2"

  default_tags {
    tags = local.mandatory_tags
  }
}