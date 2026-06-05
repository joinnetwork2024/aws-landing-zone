locals {
  mandatory_tags = {
    CostCenter  = "eks" 
    Environment = "dev"       # ← or use var.env
    Owner       = "eks Team"  
  }
}

provider "aws" {

  region = "eu-west-2" 
 
  default_tags {
    tags = local.mandatory_tags
  }
}


terraform {
required_providers {
    aws = {    source  = "hashicorp/aws", version = "~> 5.0"}
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.0" }
    helm       = { source = "hashicorp/helm", version = "~> 2.0" }
  }
  required_version = ">= 1.9"
}

# This allows Helm to talk to your new cluster
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    }
  }
}
