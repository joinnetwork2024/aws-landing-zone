locals {
  prefix                 = "${var.env}-iot"
  timestream_db_name     = coalesce(var.timestream_database_name, "iot_monitoring_${var.env}")
  firehose_buffer_size   = 128
  firehose_buffer_interval = 300   # 5 minutes
}

# ──────────────────────────────────────────────────────────────────────────────
# Kinesis Data Stream - main ingestion stream
# ──────────────────────────────────────────────────────────────────────────────
resource "aws_kinesis_stream" "iot_data" {
  name        = "${local.prefix}-data-stream"
  shard_count = var.kinesis_shard_count

  # Recommended for production - retention period
  retention_period = 24   # hours

  tags = {
    Environment = var.env
    Purpose     = "iot-real-time-ingestion"
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# Timestream - Hot path / real-time analytics
# ──────────────────────────────────────────────────────────────────────────────
# resource "aws_timestreamwrite_database" "iot" {
#   database_name = local.timestream_db_name

#   tags = {
#     Environment = var.env
#     Purpose     = "iot-hot-path"
#   }
# }

# resource "aws_timestreamwrite_table" "sensors" {
#   database_name = aws_timestreamwrite_database.iot.database_name
#   table_name    = "sensors"

#   retention_properties {
#     magnetic_store_retention_period_in_days = 365   # 1 year in magnetic
#     memory_store_retention_period_in_hours  = 24    # 1 day in memory
#   }

#   tags = {
#     Environment = var.env
#   }
# }

# ──────────────────────────────────────────────────────────────────────────────
# S3 - Cold path / long-term storage (Parquet)
# ──────────────────────────────────────────────────────────────────────────────
resource "aws_s3_bucket" "iot_archive" {
  bucket = "${local.prefix}-archive-${data.aws_caller_identity.current.account_id}"

  force_destroy = var.env == "dev" ? true : false
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.s3.arn
      }
      bucket_key_enabled = true
    }
  }

  tags = {
    Environment = var.env
    Purpose     = "iot-cold-storage"
  }
}

resource "aws_s3_bucket_versioning" "iot_archive" {
  bucket = aws_s3_bucket.iot_archive.id
  versioning_configuration {
    status = "Enabled"
  }

  
}


resource "aws_kms_key" "s3" {
  description             = "KMS key for Terraform state"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

# ──────────────────────────────────────────────────────────────────────────────
# Kinesis Firehose → S3 (Parquet conversion)
# ──────────────────────────────────────────────────────────────────────────────
resource "aws_kinesis_firehose_delivery_stream" "archive" {
  name        = "${local.prefix}-to-s3-parquet"
  destination = "extended_s3"   # ← this must match the block name below

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.iot_data.arn
    role_arn           = aws_iam_role.firehose.arn
  }

  extended_s3_configuration {   # ← CORRECT block name (was wrong before)
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = aws_s3_bucket.iot_archive.arn

    prefix             = "raw/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "errors/!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"

    buffering_size     = local.firehose_buffer_size
    buffering_interval = local.firehose_buffer_interval

    # For Parquet conversion (recommended for analytics/ML)
    data_format_conversion_configuration {
      enabled = true

      input_format_configuration {
        deserializer {
          open_x_json_ser_de {}   # assuming your IoT data is JSON
        }
      }

      output_format_configuration {
        serializer {
          parquet_ser_de {
            compression = "SNAPPY"   # good balance of size/speed
          }
        }
      }

      schema_configuration {
        role_arn      = aws_iam_role.firehose.arn
        database_name = "iot_default"          # ← IMPORTANT: Create this Glue DB/table or use real one
        table_name    = "iot_raw_parquet"
        region        = data.aws_region.current.name
      }
    }
  }

  tags = {
    Environment = var.env
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# SNS Topic for Alerts
# ──────────────────────────────────────────────────────────────────────────────
resource "aws_sns_topic" "iot_alerts" {
  name = "${local.prefix}-alerts"

  tags = {
    Environment = var.env
  }
}

resource "aws_sns_topic_subscription" "email_alert" {
  count     = var.alert_email != null ? 1 : 0
  topic_arn = aws_sns_topic.iot_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ──────────────────────────────────────────────────────────────────────────────
# IAM Roles (minimal example - expand in production)
# ──────────────────────────────────────────────────────────────────────────────
resource "aws_iam_role" "firehose" {
  name = "${local.prefix}-firehose-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "firehose.amazonaws.com" }
    }]
  })
}

# Attach necessary policies (S3, Kinesis, Glue, Logs)
resource "aws_iam_role_policy" "firehose_policy" {
  name = "firehose-delivery-policy"
  role = aws_iam_role.firehose.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # S3 access
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:PutObjectAcl"]
        Resource = "${aws_s3_bucket.iot_archive.arn}/*"
      },
      {
        effect = "Allow"
        action = [
         "kms:Decrypt",
         "kms:GenerateDataKey"
    ]
    resource = [aws_kms_key.s3.arn]
      },
      {
      Effect   = "Allow"
      Action   = [
        "glue:GetDatabase",
        "glue:GetDatabases",
        "glue:GetTable",
        "glue:GetTables",
        "glue:GetTableVersion",
        "glue:GetTableVersions",
        "glue:GetPartitions"
      ]
      Resource = "*"
      },
      # Kinesis read
      {
        Effect   = "Allow"
        Action   = ["kinesis:DescribeStream", "kinesis:GetShardIterator", "kinesis:GetRecords", "kinesis:ListShards"]
        Resource = aws_kinesis_stream.iot_data.arn
      },
      # CloudWatch Logs
      {
        Effect   = "Allow"
        Action   = ["logs:PutLogEvents"]
        Resource = "*"
      }
    ]
  })
}

# Data sources for cleaner references
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_glue_catalog_database" "iot" {
  name = "iot_default"
}

resource "aws_glue_catalog_table" "iot_raw_parquet" {
  name          = "iot_raw_parquet"
  database_name = aws_glue_catalog_database.iot.name

  table_type = "EXTERNAL_TABLE"

  storage_descriptor {
    columns {
      name = "device_id"
      type = "string"
    }
    columns {
      name = "timestamp"
      type = "timestamp"
    }
    columns {
      name = "temperature"
      type = "double"
    }
    # Add more columns matching your IoT JSON payload
  }

  partition_keys {
    name = "year"
    type = "string"
  }
  partition_keys {
    name = "month"
    type = "string"
  }
  partition_keys {
    name = "day"
    type = "string"
  }
}