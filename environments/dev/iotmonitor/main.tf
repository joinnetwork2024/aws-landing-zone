# main.tf (or environments/dev/main.tf)

module "dev_network" {
  source = "../../../modules/vpc"

  vpc_id = "10.20.0.0/16"
  env    = "dev"
}

module "iot_monitoring" {
  source = "../../../modules/iot_monitor"

  env             = "dev"
  vpc_id          = module.dev_network.vpc_id
  private_subnets = module.dev_network.private_subnets # most services here are private
  # public_subnets  = module.dev_network.public_subnets   # only if you expose something (e.g. Grafana)

  # Optional - you can pass these from variables/secrets
  timestream_database_name = "iot_monitoring_dev"
  kinesis_shard_count      = 50 # adjust according to expected load
  alert_email              = "joejo201770@gmail.com"
}