variable "env" {
  default = "dev"
}

variable "cloud_provider" {
  default = "aws" # or "azure"
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


