variable "env" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "cloud_provider" {
  description = "Cloud provider to deploy to (aws or azure)"
  type        = string
  default     = "aws"
}

variable "vpc_id" {
  description = "VPC ID from network module"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "kinesis_shard_count" {
  description = "Number of shards for Kinesis stream (scale for throughput)"
  type        = number
  default     = 100
}

variable "alert_email" {
  description = "Email for SNS alerts"
  type        = string
}

variable "sagemaker_model" {
  description = "SageMaker model name for traffic forecasting"
  type        = string
}

variable "aws_region" {
  description = "AWS region (if cloud_provider = aws)"
  type        = string
  default     = "eu-west-2"
}

variable "edge_enabled" {
  description = "Enable edge processing (Greengrass/IoT Edge)"
  type        = bool
  default     = true
}

