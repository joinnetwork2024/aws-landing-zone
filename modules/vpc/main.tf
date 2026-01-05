resource "aws_vpc" "main" {
  cidr_block           = var.vpc_id
  enable_dns_hostnames = true
  tags = {
    Name        = "${var.env}-vpc"
    Environment = var.env
    ManagedBy   = "Terraform"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_id, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags              = { Name = "${var.env}-private-${count.index}" }
}

resource "aws_subnet" "public" {
  count  = 2
  vpc_id = aws_vpc.main.id
  # FIX: Offset by 2. Creates 10.10.2.0/24 and 10.10.3.0/24
  cidr_block        = cidrsubnet(var.vpc_id, 8, count.index + 2)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags              = { Name = "${var.env}-public-${count.index}" }
}

data "aws_availability_zones" "available" {}



####Internet
# 1. Create the Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.env}-igw" }
}

# 2. Create a Route Table for the Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = { Name = "${var.env}-public-rt" }
}

# 3. Associate the Route Table with your Public Subnets
resource "aws_route_table_association" "public" {
  count          = 1
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}