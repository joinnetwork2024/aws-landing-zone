# Outputs (Updated: Added more for integration)
output "stream_arn" {
  value = var.cloud_provider == "aws" ? aws_kinesis_stream.traffic_data[0].arn : null  # Azure placeholder
}

output "endpoint_name" {
  value = var.cloud_provider == "aws" ? aws_sagemaker_endpoint.traffic_forecast[0].name : null
}

output "sns_topic_arn" {
  value = var.cloud_provider == "aws" ? aws_sns_topic.traffic_alerts[0].arn : null
}

output "api_id" {
  value = var.cloud_provider == "aws" ? aws_apigatewayv2_api.traffic_api[0].id : null
}

# Inference Stage Outputs (Core for MLSecOps Visibility)
output "sagemaker_endpoint_name" {
  description = "Name of the Smart City real-time traffic prediction endpoint"
  value       = try(aws_sagemaker_endpoint.traffic_forecast[0].name, null)
}

output "sagemaker_endpoint_arn" {
  description = "ARN for IAM policies, GuardDuty integration, and monitoring"
  value       = try(aws_sagemaker_endpoint.traffic_forecast[0].arn, null)
}

output "sagemaker_model_name" {
  description = "Deployed model name for registry tracking"
  value       = try(aws_sagemaker_model.traffic_forecast[0].name, null)
}

# Storage & Lineage Outputs
output "traffic_archive_bucket_name" {
  description = "Central archive bucket (cold storage + data capture)"
  value       = try(aws_s3_bucket.traffic_archive[0].bucket, null)
}

output "traffic_archive_bucket_arn" {
  description = "ARN for cross-resource policies"
  value       = try(aws_s3_bucket.traffic_archive[0].arn, null)
}

output "data_capture_s3_prefix" {
  description = "Prefix for SageMaker captured inputs/outputs – feed to Model Monitor"
  value       = "monitoring/data-capture/${var.env}/"
}

output "full_data_capture_location" {
  description = "Complete S3 path for auditing live predictions"
  value       = try("s3://${aws_s3_bucket.traffic_archive[0].bucket}/monitoring/data-capture/${var.env}/", null)
}

# Streaming & Alerting
output "kinesis_stream_name" {
  value = try(aws_kinesis_stream.traffic_data[0].name, null)
}

output "sns_alert_topic_arn" {
  value = try(aws_sns_topic.traffic_alerts[0].arn, null)
}

# API (if external exposure needed)
output "api_gateway_url" {
  description = "Base URL for external prediction queries"
  value       = try(aws_apigatewayv2_api.traffic_api[0].api_endpoint, null)
}