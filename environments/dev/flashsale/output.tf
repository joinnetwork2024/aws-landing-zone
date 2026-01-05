output "dev_vpc_info" {
  value = module.dev_network.vpc_id
}

output "dev_private_subnets" {
  value = module.dev_network.private_subnets
}

output "dev_private_public" {
  value = module.dev_network.public_subnets
}
