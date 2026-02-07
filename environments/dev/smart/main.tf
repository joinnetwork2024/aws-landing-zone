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
  kinesis_shard_count = 1                              # Scaled for 200K events/sec
  alert_email         = "traffic-alerts@city.gov"
  sagemaker_model     = "traffic-forecast-lstm" # Example model name

  # Azure-specific vars if needed
}
locals {
  # Define a map for your common tags
  prefix = "${var.env}-smart-traffic"

  common_tags = {
    Project     = "AI Training Data"
    Environment = "dev"
    CostCenter  = "Sensitive-ML"
  }
}

# # Timestream Ingest Endpoint
# resource "aws_vpc_endpoint" "timestream_ingest" {
#   count             = var.cloud_provider == "aws" ? 1 : 0
#   vpc_id            = module.dev_network.vpc_id # Direct reference
#   service_name      = "com.amazonaws.${var.aws_region}.timestream.write"
#   vpc_endpoint_type = "Interface"
#   subnet_ids        = module.dev_network.private_subnets # Direct
#   security_group_ids = [

#     aws_security_group.timestream_endpoints_sg.id # Or dedicated
#   ]
#   private_dns_enabled = true

#   tags = local.common_tags
# }

# # Timestream Query Endpoint
# resource "aws_vpc_endpoint" "timestream_query" {
#   count             = var.cloud_provider == "aws" ? 1 : 0
#   vpc_id            = module.dev_network.vpc_id
#   service_name      = "com.amazonaws.${var.aws_region}.timestream.query"
#   vpc_endpoint_type = "Interface"
#   subnet_ids        = module.dev_network.private_subnets
#   security_group_ids = [
#     aws_security_group.timestream_endpoints_sg.id
#   ]
#   private_dns_enabled = true

#   tags = local.common_tags
# }
# Multi-AZ NAT (resilient outbound)
resource "aws_eip" "nat" {
  count = var.cloud_provider == "aws" ? length(module.dev_network.public_subnets) : 0
  vpc   = true
  tags  = merge(local.common_tags, { Purpose = "nat-outbound-timestream" })
}

resource "aws_nat_gateway" "private_outbound" {
  count         = var.cloud_provider == "aws" ? length(module.dev_network.public_subnets) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = module.dev_network.public_subnets[count.index]
  tags          = merge(local.common_tags, { Purpose = "timestream-public-outbound" })
}

# NAT Route on Private RTs
resource "aws_route" "private_to_nat" {
  count                  = var.cloud_provider == "aws" ? length(module.dev_network.private_route_table_ids) : 0
  route_table_id         = module.dev_network.private_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.private_outbound[count.index].id
}