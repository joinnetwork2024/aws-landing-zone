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

variable "allowed_regions" {
  description = "A list of AWS regions that are allowed for deployments."
  type        = list(string)
  default = [
    "eu-west-2",    # London
    "eu-central-1", # Frankfurt
  ]
}

variable "log_archive_account_id" {
  description = "ID-MGMT"
  type        = string
  default     = "466984621504"
}