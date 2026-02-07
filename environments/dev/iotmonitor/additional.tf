# Dynamic context for ARNs and policies (standard Terraform pattern)
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_vpc" "selected" {
  id = module.dev_network.vpc_id
}

locals {
  # Define a map for your common tags
  prefix = "${var.env}-smart-traffic"

  common_tags = {
    Project     = "IOT"
    Owner       = "APP team"
    Environment = "dev"
    CostCenter  = "IOTMONITOR"
  }
}

# KMS Key for OpenSearch (dedicated encryption for telemetry)
resource "aws_kms_key" "opensearch" {
  description             = "KMS key for OpenSearch IoT telemetry encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 30
}

# IAM Master Role (fine-grained, ABAC-ready)
resource "aws_iam_role" "opensearch_master" {
  name = "${var.project_name}-opensearch-master"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "opensearchservice.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "opensearch_master" {
  role       = aws_iam_role.opensearch_master.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonOpenSearchServiceFullAccess" # Narrow in prod
}

# OpenSearch Domain – VPC-private, encrypted, fine-grained access
resource "aws_opensearch_domain" "iot" {
  domain_name    = "${var.project_name}-opensearch"
  engine_version = "OpenSearch_2.13" # Latest stable

  cluster_config {
    instance_type          = "r6g.large.search"
    instance_count         = 3
    zone_awareness_enabled = true
    zone_awareness_config {
      availability_zone_count = 2
    }
  }

  vpc_options {
    subnet_ids         = module.dev_network.private_subnets
    security_group_ids = [aws_security_group.opensearch.id]
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 100
  }

  encrypt_at_rest {
    enabled    = true
    kms_key_id = aws_kms_key.opensearch.arn
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = false
    master_user_options {
      master_user_arn = aws_iam_role.opensearch_master.arn
    }
  }

  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = "*" } # Hardened: Scope to specific roles (e.g., Firehose, Lambda processors)
        Action    = "es:ESHttp*"
        Resource  = "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.project_name}-opensearch/*"
        Condition = { IpAddress = { "aws:SourceIp" = [module.dev_network.vpc_cidr_block] } } # VPC-only
      }
    ]
  })

}

# Security Group – Least-privilege HTTPS from VPC
resource "aws_security_group" "opensearch" {
  name        = "${var.project_name}-opensearch-sg"
  description = "Allow HTTPS from VPC for OpenSearch telemetry"
  vpc_id      = module.dev_network.vpc_id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.dev_network.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# Firehose to OpenSearch (hot-path) with S3 backup
resource "aws_kinesis_firehose_delivery_stream" "to_opensearch" {
  name        = "${var.project_name}-to-opensearch"
  destination = "opensearch"

  kinesis_source_configuration {
    kinesis_stream_arn = module.iot_monitoring.kinesis_stream_arn
    role_arn           = module.iot_monitoring.firehose_role_arn
  }

  opensearch_configuration {
    domain_arn            = aws_opensearch_domain.iot.arn
    role_arn              = module.iot_monitoring.firehose_role_arn
    index_name            = "iot-telemetry" # Base name – rotation appends date
    index_rotation_period = "OneDay"        # Auto: iot-telemetry-2026-01-28

    buffering_size     = 64
    buffering_interval = 60

    s3_backup_mode = "AllDocuments" # Resilience for ML retraining

    s3_configuration {
      role_arn   = module.iot_monitoring.firehose_role_arn
      bucket_arn = module.iot_monitoring.s3_archive_bucket_arn
      prefix     = "opensearch-backup/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"

      error_output_prefix = "opensearch-errors/!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
      buffering_size      = 64
      buffering_interval  = 300
    }
  }

}

# Extend Firehose policy for OpenSearch
resource "aws_iam_role_policy" "firehose_opensearch" {
  name = "opensearch-delivery"
  role = module.iot_monitoring.firehose_role_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "es:DescribeDomain",
          "es:ESHttpPost",
          "es:ESHttpPut",
          "es:ESHttpGet"
        ]
        Resource = "${aws_opensearch_domain.iot.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["es:DescribeDomain", "es:ESHttpPost", "es:ESHttpPut"]
        Resource = "${aws_opensearch_domain.iot.arn}/*"
      }
    ]
  })
}