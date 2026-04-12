variable "db_password" {
  description = "db_password"
  type        = string
  default     = "TestingSuperStrongPass"
}

variable "aws_region" {
  description = "AWS region"
  default     = "eu-west-2"
  type        = string
}


variable "project_name" {
  description = "Project name"
  default     = "landing"
  type        = string
}