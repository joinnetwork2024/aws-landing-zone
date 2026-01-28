# # Data Source for VPC CIDR (dynamic, conditional on AWS)
# data "aws_vpc" "selected" {
#   count = var.cloud_provider == "aws" ? 1 : 0
#   id    = module.dev_network.vpc_id # From root-passed var (e.g., module.dev_network.vpc_id in root call)
# }

# # Optional: Dedicated SG for Timestream Endpoints (least-privilege HTTPS from VPC CIDR)
# resource "aws_security_group" "timestream_endpoints_sg" {
#   name        = "${local.prefix}-timestream-endpoints-sg" # Or use var.env
#   description = "Inbound HTTPS only for Timestream private endpoints (hot storage isolation)"
#   vpc_id      = module.dev_network.vpc_id # Direct from VPC module

#   ingress {
#     description = "HTTPS from VPC CIDR (prevents public metric exposure)"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = [module.dev_network.vpc_cidr_block] # Assume VPC module outputs cidr_block as vpc_cidr
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = local.common_tags # Your root locals
# }