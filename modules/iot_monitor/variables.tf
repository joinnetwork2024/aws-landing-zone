variable "env" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be deployed"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "timestream_database_name" {
  description = "Name of the Timestream database"
  type        = string
  default     = null
}

variable "kinesis_shard_count" {
  description = "Number of shards for Kinesis Data Stream"
  type        = number
  default     = 20
}

variable "alert_email" {
  description = "Email address for receiving IoT anomaly alerts"
  type        = string
  default     = null
}