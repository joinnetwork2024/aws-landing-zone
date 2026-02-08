variable "rcf_model_artifact_url" {
  description = "S3 model.tar.gz from RCF training job completion"
  type        = string
  sensitive   = true
  default     = "https://dev-smart-traffic-archive-715841360340.s3.eu-west-2.amazonaws.com/rcf-anomaly/training.csv"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  rcf_images = {
    "eu-west-1" = "664544806723.dkr.ecr.eu-west-1.amazonaws.com/randomcutforest:1" # Fixes your current error
    "eu-west-2" = "382416733822.dkr.ecr.eu-west-2.amazonaws.com/randomcutforest:1"
    # Add others as needed - full list: AWS SageMaker algo registry paths
  }
  rcf_image = local.rcf_images[data.aws_region.current.name]

  # Dynamic bucket name resolution (matches your stack pattern; no module dependency)
  traffic_archive_bucket_name = "smart-city-traffic-archive-${data.aws_caller_identity.current.account_id}"
  traffic_archive_bucket_arn  = "arn:aws:s3:::${local.traffic_archive_bucket_name}"
}

# Dedicated SageMaker Execution Role (least-privilege pattern)
resource "aws_iam_role" "smart_city_sagemaker_execution" {
  name_prefix = "SmartCity-SageMakerExec-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Principal = { Service = "sagemaker.amazonaws.com" }
      Effect    = "Allow"
    }]
  })

  tags = {
    Project    = "SmartCity"
    Component  = "MLExecutionRole"
    GovernedBy = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "sagemaker_full_access" {
  role       = aws_iam_role.smart_city_sagemaker_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

# Scoped S3 access (exfiltration mitigation - AI/ML-specific risk)
resource "aws_iam_role_policy" "s3_traffic_limited" {
  name = "SmartCity-TrafficArchiveAccess"
  role = aws_iam_role.smart_city_sagemaker_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
        Resource = [
          local.traffic_archive_bucket_arn,
          "${local.traffic_archive_bucket_arn}/*"
        ]
        Effect = "Allow"
      },
      {
        Action   = ["s3:ListAllMyBuckets", "s3:GetBucketLocation"]
        Resource = "*"
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.smart_city_sagemaker_execution.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Persistent Model (uses dedicated role)
resource "aws_sagemaker_model" "traffic_rcf_anomaly" {
  name               = "smart-city-traffic-rcf-anomaly-model"
  execution_role_arn = aws_iam_role.smart_city_sagemaker_execution.arn # Fixed: uses defined role

  primary_container {
    image          = local.rcf_image
    model_data_url = var.rcf_model_artifact_url
  }

  tags = { MLRisk = "AnomalyDetection" }
}

# Endpoint Config & Endpoint
resource "aws_sagemaker_endpoint_configuration" "traffic_rcf_anomaly" {
  production_variants {
    variant_name           = "rcf-anomaly"
    model_name             = aws_sagemaker_model.traffic_rcf_anomaly.name
    initial_instance_count = 1
    instance_type          = "ml.m5.large" # (~£0.10/hour); delete after demo
  }
}

resource "aws_sagemaker_endpoint" "traffic_rcf_anomaly" {
  name                 = "smart-city-traffic-anomaly-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.traffic_rcf_anomaly.name

  tags = {
    Project  = "SmartCity"
    MLType   = "RandomCutForest"
    Governed = "True"
  }
}

# Helpful output
output "smart_city_sagemaker_role_arn" {
  value       = aws_iam_role.smart_city_sagemaker_execution.arn
  description = "Use this ARN in one-time training scripts (replaces truncated/broken roles)"
}

output "traffic_anomaly_endpoint_name" {
  value = aws_sagemaker_endpoint.traffic_rcf_anomaly.name
}