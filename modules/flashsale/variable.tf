variable "vpc_id" { 
  type        = string
  description = "The ID of the VPC"
}

variable "env" {
  description = "Environment that you are using"
  type        = string
}


variable "private_subnets" {
  description = "private_subnet_group"
  type        = list(string)
}

variable "db_password" {
  description = "db_password"
  type        = string
}

variable "public_subnets" {
  description = "public_subnets"
  type        = list(string)
}