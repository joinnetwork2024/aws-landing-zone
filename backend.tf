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

}

resource "aws_s3_bucket" "tf_state" {
  bucket = "terraform-landingzone-state-joinnetwork2021"
  # (Other config here, but minimal is fine for import)
}

# resource "aws_s3_bucket" "tf_state" {
#   bucket = "terraform-landingzone-state-joinnetwork2021"

#   tags = {
#     Name        = "Terraform State Bucket"
#     Environment = "Dev"
#   }
# }

resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}