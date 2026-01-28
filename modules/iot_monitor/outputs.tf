output "kinesis_stream_name" {
  description = "Name of the governed Kinesis Data Stream for real-time IoT telemetry ingestion (source for Firehose/OpenSearch and potential SageMaker processing)."
  value       = aws_kinesis_stream.iot_data.name
}

output "kinesis_stream_arn" {
  description = "ARN of the governed Kinesis stream – use for IoT Topic Rules (enforces ingestion into secured pipeline, mitigates data poisoning from ungoverned sources)."
  value       = aws_kinesis_stream.iot_data.arn
}

output "s3_archive_bucket_name" {
  description = "Name of the cold-path S3 bucket for Parquet-archived telemetry (durable storage for compliance audits and periodic ML retraining)."
  value       = aws_s3_bucket.iot_archive.bucket
}

output "s3_archive_bucket_arn" {
  description = "ARN of the cold-path archive bucket – for IAM policies scoping backup access (prevents exfiltration of raw ML datasets)."
  value       = aws_s3_bucket.iot_archive.arn
}

output "firehose_archive_name" {
  description = "Name of the Firehose delivery stream for S3 Parquet archiving (with error partitioning for clean ML datasets)."
  value       = aws_kinesis_firehose_delivery_stream.archive.name
}


output "sns_alerts_topic_arn" {
  description = "ARN of the SNS topic for anomaly/cost alerts (integrate with Lambda → SageMaker inference notifications)."
  value       = aws_sns_topic.iot_alerts.arn
}

output "firehose_role_arn" {
  description = "The ARN of the IAM role for OpenSearch"
  value       = aws_iam_role.firehose.arn
}

output "firehose_role_id" {
  description = "The ARN of the IAM role for OpenSearch"
  value       = aws_iam_role.firehose.id
}