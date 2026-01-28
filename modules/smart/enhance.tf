# Data Source for Account ID (conditional – fix indexing in policy)
data "aws_caller_identity" "current" {
  count = var.cloud_provider == "aws" ? 1 : 0
}

# Dedicated Least-Privilege Role for Step Functions Retraining Orchestration
resource "aws_iam_role" "stepfunctions_sagemaker" {
  count = var.cloud_provider == "aws" ? 1 : 0

  name = "${local.prefix}-sfn-sagemaker"  # Consistent naming (dev-smart-traffic-sfn-sagemaker)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "states.amazonaws.com" }
    }]
  })

  tags = local.common_tags  # Or local.effective_tags
}

# Broad SageMaker Invocation + S3/Logs (scope Resource in prod)
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
          "sagemaker:UpdateEndpoint"
        ]
        Resource = "*"  # Scope to specific ARNs in prod (e.g., training jobs prefixed)
      },
      {
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = aws_iam_role.sagemaker[0].arn  # Scoped PassRole for training
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

# Scoped Events Permissions for Managed Rules (Retraining Triggers)
resource "aws_iam_role_policy" "sfn_managed_rules" {
  count = var.cloud_provider == "aws" ? 1 : 0
  name  = "${local.prefix}-sfn-managed-rules"
  role  = aws_iam_role.stepfunctions_sagemaker[0].id  # Fixed: Reference existing consolidated role

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "events:PutRule",
          "events:PutTargets",
          "events:DescribeRule",
          "events:DeleteRule",
          "events:RemoveTargets",
          "events:ListRules",
          "events:ListTargetsByRule"
        ]
        Resource = "arn:aws:events:${var.aws_region}:${data.aws_caller_identity.current[0].account_id}:rule/StepFunctions*"  # Fixed: [0] indexing + scoped to SFN-managed rules
      }
    ]
  })
}

# Step Functions State Machine for Retraining (uses consolidated role)
resource "aws_sfn_state_machine" "traffic_model_retrain" {
  count = var.cloud_provider == "aws" ? 1 : 0

  name     = "${local.prefix}-retrain"
  role_arn = aws_iam_role.stepfunctions_sagemaker[0].arn  # Consolidated role

  definition = jsonencode({
    Comment = "Orchestrate SageMaker DeepAR training + model update on traffic data lineage"
    StartAt = "StartTraining"
    States = {
      StartTraining = {
        Type       = "Task"
        Resource   = "arn:aws:states:::sagemaker:createTrainingJob.sync"
        Parameters = {
          "TrainingJobName.$" = "States.Format('${local.prefix}-training-{}', $$.Execution.StartTime)"
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
        Next = "Success"  # Expand with bias evaluation, registry promotion states
      }
      Success = {
        Type = "Succeed"
      }
    }
  })

  tags = local.common_tags
}