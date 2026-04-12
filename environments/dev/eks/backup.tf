terraform {
  backend "s3" {
    bucket  = "terraform-landingzone-state-2017"
    key     = "org-root/terraform_eks.tfstate"
    region  = "eu-west-2"
    encrypt = true

    # use_lockfile = true
  }
}