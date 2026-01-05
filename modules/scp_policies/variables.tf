variable "allowed_regions" {
  description = "List of AWS regions where resource creation is allowed"
  type        = list(string)
  default = ["us-east-1", "us-west-2"] 
}

variable "target_id" {
  description = "The ID of the Organization Root or OU where the SCP will be attached"
  type        = string
}

variable "aws_region" {
  description = "The AWS region "
  type        = string
  default     = "eu-west-2"
}

variable "project_prefix" {
  description = "A prefix for naming resources to ensure uniqueness within the organization."
  type        = string
  default     = "joinnetwork" # You can change this default
}


variable "cloudtrail_s3_bucket" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "terraform-landingzone-state-joinnetwork2021"
}

variable "log_archive_account_id" {
  description = "ID-MGMT"
  type        = string
  default     = "466984621504"
}