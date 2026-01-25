module "dev_network" {
  source = "../../../modules/vpc"

  # Pass the variables required by your module
  vpc_id = "10.10.0.0/16"
  env    = "dev"
}

module "flashsale_system" {
  source          = "../../../modules/flashsale"
  env             = "dev"
  vpc_id          = module.dev_network.vpc_id
  public_subnets  = module.dev_network.public_subnets
  private_subnets = module.dev_network.private_subnets
  db_password     = var.db_password # Pass from a secret variable
}








