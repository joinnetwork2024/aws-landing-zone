data "aws_caller_identity" "current" {}

data "aws_sagemaker_pre_built_ecr_image" "xgboost" {
  repository_name = "xgboost"
  image_tag       = "1.7-1"
}

resource "aws_sagemaker_model" "traffic_model" {
  name               = "smartcity-traffic-xgboost-${var.environment}"
  execution_role_arn = aws_iam_role.sagemaker.arn

  primary_container {
    image          = data.aws_sagemaker_pre_built_ecr_image.xgboost.image_uri
    model_data_url = var.model_s3_path
  }

  vpc_config {
    security_group_ids = [aws_security_group.sagemaker.id]
    subnets            = var.private_subnet_ids
  }
}

resource "aws_sagemaker_endpoint_configuration" "traffic_config" {
  name = "smartcity-traffic-endpoint-config-${var.environment}"

  production_variants {
    variant_name           = "primary"
    model_name             = aws_sagemaker_model.traffic_model.name
    initial_instance_count = 1
    instance_type          = "ml.m5.large"  # Smaller/cheaper for dev
  }

  data_capture_config {
    enable_capture             = true
    initial_sampling_percentage = 100
    destination_s3_uri         = "s3://smartcity-monitoring-dev-${data.aws_caller_identity.current.account_id}/"
    capture_options { capture_mode = "Input" }
    capture_options { capture_mode = "Output" }
  }
}

resource "aws_sagemaker_endpoint" "traffic_endpoint" {
  name                 = "smartcity-traffic-predictor-${var.environment}"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.traffic_config.name
}

# Least-privilege role + SG (VPC-only)
resource "aws_iam_role" "sagemaker" { ... }  # As in previous example
resource "aws_security_group" "sagemaker" { ... }  # Egress-only