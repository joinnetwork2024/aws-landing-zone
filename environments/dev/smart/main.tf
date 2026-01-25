module "dev_network" {
  source = "../../../modules/vpc"

  # Pass the variables required by your module
  vpc_id = "10.30.0.0/16"
  env    = "dev"
}

module "smart_city_traffic" {
  source = "../../../modules/smart"

  env                 = var.env
  cloud_provider      = var.cloud_provider
  vpc_id              = module.dev_network.vpc_id
  private_subnets     = module.dev_network.private_subnets
  public_subnets      = module.dev_network.public_subnets # For API Gateway or public endpoints
  kinesis_shard_count = 100                               # Scaled for 200K events/sec
  alert_email         = "traffic-alerts@city.gov"
  sagemaker_model     = "traffic-forecast-lstm" # Example model name

  # Azure-specific vars if needed
}






