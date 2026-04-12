module "dev_network" {
  source = "../../../modules/vpc"

  # Pass the variables required by your module
  vpc_id = "10.168.0.0/16"
  env    = "dev-eks"

}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "my-eks-cluster"
  cluster_version = "1.32"

  vpc_id     = module.dev_network.vpc_id
  subnet_ids = module.dev_network.public_subnets

  eks_managed_node_groups = {
    general = {
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 2
      desired_size   = 1
    }
  }
}

#   resource "kubernetes_namespace" "argocd" {
#   metadata {
#     name = "argocd"
#   }
# }

# resource "helm_release" "argocd" {
#   name       = "argocd"
#   repository = "https://argoproj.github.io/argo-helm"
#   chart      = "argo-cd"
#   namespace  = kubernetes_namespace.argocd.metadata[0].name
#   version    = "7.7.0" # Latest stable chart version

#   set {
#     name  = "server.service.type"
#     value = "LoadBalancer" # Makes the UI accessible via a URL
#   }
# }