locals {
  mandatory_tags = {
    CostCenter  = "Flashsale" # ← change to your real value
    Environment = "dev"       # ← or use var.env
    Owner       = "APP Team"  # or your name/email
  }
}

provider "aws" {

  region = "eu-west-2" # your region
  endpoints {
    timestreamwrite = "https://ingest.timestream.eu-west-1.amazonaws.com"
  }
  default_tags {
    tags = local.mandatory_tags
  }
}