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