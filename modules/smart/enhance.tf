# Convert CSV to DeepAR JSONLines format (use Lambda or script; for simplicity, assume preprocessed)
# S3 path for training data: s3://${aws_s3_bucket.traffic_archive[0].bucket}/training/traffic_data.jsonl

# resource "aws_sagemaker_training_job" "traffic_forecast_training" {
#   count = var.cloud_provider == "aws" ? 1 : 0

#   name = "${local.prefix}-training-job"
#   role_arn = aws_iam_role.sagemaker[0].arn

#   algorithm_specification {
#     training_image = "462105765813.dkr.ecr.${var.aws_region}.amazonaws.com/forecasting-deepar:1"  # DeepAR algo image (adjust region)
#     training_input_mode = "File"
#   }

#   input_data_config {
#     channel_name = "train"
#     data_source {
#       s3_data_source {
#         s3_data_type = "S3Prefix"
#         s3_uri = "s3://${aws_s3_bucket.traffic_archive[0].bucket}/training/"
#         s3_data_distribution_type = "FullyReplicated"
#       }
#     }
#     content_type = "application/jsonlines"
#     compression_type = "None"
#   }

#   output_data_config {
#     s3_output_path = "s3://${aws_s3_bucket.traffic_archive[0].bucket}/models/"
#   }

#   resource_config {
#     instance_type = "ml.m5.large"
#     instance_count = 1
#     volume_size_in_gb = 10
#   }

#   stopping_condition {
#     max_runtime_in_seconds = 3600
#   }

#   hyper_parameters = {
#     "time_freq" = "H"  # Hourly
#     "context_length" = "24"  # Look back 1 day
#     "prediction_length" = "1"  # Predict next hour
#     "epochs" = "100"
#     "num_layers" = "2"
#     "num_cells" = "50"
#     "mini_batch_size" = "32"
#     "learning_rate" = "0.001"
#   }

#   vpc_config {
#     security_group_ids = [aws_security_group.sagemaker_sg[0].id]
#     subnets = var.private_subnets
#   }

#   enable_network_isolation = true
#   enable_managed_spot_training = false
# }

resource "aws_iam_role" "stepfunctions_sagemaker" {
  count = var.cloud_provider == "aws" ? 1 : 0

  name = "${local.prefix}-sfn-sagemaker"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "states.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "stepfunctions_sagemaker_policy" {
  count = var.cloud_provider == "aws" ? 1 : 0

  name = "${local.prefix}-sfn-sagemaker-policy"
  role = aws_iam_role.stepfunctions_sagemaker[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "sagemaker:CreateTrainingJob",
          "sagemaker:DescribeTrainingJob",
          "sagemaker:StopTrainingJob",
          "sagemaker:CreateModel",
          "sagemaker:DescribeModel",
          "sagemaker:CreateEndpointConfig",
          "sagemaker:CreateEndpoint",
          "sagemaker:UpdateEndpoint",
          "iam:PassRole"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
        Resource = ["${aws_s3_bucket.traffic_archive[0].arn}", "${aws_s3_bucket.traffic_archive[0].arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "*"
      }
    ]
  })
}

# Minimal Step Functions state machine example (expand with full ASL definition)
resource "aws_sfn_state_machine" "traffic_model_retrain" {
  count = var.cloud_provider == "aws" ? 1 : 0

  name     = "${local.prefix}-retrain"
  role_arn = aws_iam_role.stepfunctions_sagemaker[0].arn

  definition = jsonencode({
    Comment = "Orchestrate SageMaker training + model update"
    StartAt = "StartTraining"
    States = {
      StartTraining = {
        Type       = "Task"
        Resource   = "arn:aws:states:::sagemaker:createTrainingJob.sync"
        Parameters = {
          "TrainingJobName.$" = "States.Format('${local.prefix}-training-{}', $$.Execution.StartTime)"  # ← FIXED: "Name.$" syntax
          AlgorithmSpecification = {
            TrainingImage     = "462105765813.dkr.ecr.${var.aws_region}.amazonaws.com/forecasting-deepar:1"
            TrainingInputMode = "File"
          }
          RoleArn = aws_iam_role.sagemaker[0].arn
          InputDataConfig = [{
            ChannelName = "train"
            DataSource = {
              S3DataSource = {
                S3DataType              = "S3Prefix"
                S3Uri                   = "s3://${aws_s3_bucket.traffic_archive[0].bucket}/training/"
                S3DataDistributionType  = "FullyReplicated"
              }
            }
            ContentType      = "application/jsonlines"
            CompressionType  = "None"
          }]
          OutputDataConfig = {
            S3OutputPath = "s3://${aws_s3_bucket.traffic_archive[0].bucket}/models/"
          }
          ResourceConfig = {
            InstanceType     = "ml.m5.large"
            InstanceCount    = 1
            VolumeSizeInGB   = 10
          }
          StoppingCondition = {
            MaxRuntimeInSeconds = 3600
          }
          HyperParameters = {
            time_freq         = "H"
            context_length    = "24"
            prediction_length = "1"
            epochs            = "100"
            num_layers        = "2"
            num_cells         = "50"
            mini_batch_size   = "32"
            learning_rate     = "0.001"
          }
          VpcConfig = {
            SecurityGroupIds = [aws_security_group.sagemaker_sg[0].id]
            Subnets          = var.private_subnets
          }
          EnableNetworkIsolation   = true
          EnableManagedSpotTraining = false
        }
        Next = "Success"  # ← Expand later with more states (CreateModel, UpdateEndpoint, etc.)
      }
      Success = {
        Type = "Succeed"
      }
    }
  })
}