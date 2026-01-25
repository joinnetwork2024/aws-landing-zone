module "aviatrix_controller" {
  source          = "../../../modules/aviatrix_controller"
  aviatrix_ami_id = "ami-0123456789abcdef0"
  subnet_id       = module.ava_admin.public_subnets # Reference existing networking module
  vpc_id          = module.ava_admin.vpc_id
  key_name        = "my-key"
}

module "ava_admin" {
  source = "../../../modules/vpc"

  # Pass the variables required by your module
  vpc_id = "10.20.0.0/16"
  env    = "prd"
}