output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block for dynamic SG ingress rules (e.g., Timestream endpoints isolation in Smart City hot storage)"
  value       = aws_vpc.main.cidr_block
}
# Private Route Table IDs (list for multi-AZ NAT)
output "private_route_table_ids" {
  description = "List of private route table IDs for NAT outbound route (public Timestream access from private subnets)"
  value       = aws_route_table.private[*].id
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  value       = aws_subnet.private[*].cidr_block 
}
