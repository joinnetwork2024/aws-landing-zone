terraform {
  backend "local" {
    # bucket         = "terraform-landingzone-state-joinnetwork2021"
    # key            = "org-root/main.tfstate"
    # region         = "eu-west-2"
    # dynamodb_table = "terraform-locks"
    # encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5"
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = local.common_tags # Referencing the local variable
  }
}

resource "aws_s3_bucket" "tf_state" {
  bucket = "terraform-landingzone-state-2017"
  # (Other config here, but minimal is fine for import)

  # Modern Object Ownership
  force_destroy = false
  tags = local.common_tags
}


resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
  }
}

resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
  
}

