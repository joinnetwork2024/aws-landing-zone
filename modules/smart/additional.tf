resource "aws_iam_role_policy" "firehose_glue" {
  count = var.cloud_provider == "aws" ? 1 : 0
  name  = "${local.prefix}-firehose-glue"
  role  = aws_iam_role.firehose[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "glue:GetTable",
          "glue:GetTableVersions",
          "glue:GetDatabases",
          "glue:GetPartitions"
        ]
        Resource = "*"  # Scope to specific Glue catalog/table ARN in prod
      }
    ]
  })
}

resource "aws_iam_role_policy" "sagemaker_ecr" {
  count = var.cloud_provider == "aws" ? 1 : 0
  name  = "${local.prefix}-sagemaker-ecr"
  role  = aws_iam_role.sagemaker[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "arn:aws:ecr:${var.aws_region}:462105765813:repository/*"  # Scoped to AWS managed repos
      }
    ]
  })
}

resource "aws_iam_role_policy" "sagemaker_ecr_deepar" {
  count = var.cloud_provider == "aws" ? 1 : 0
  name  = "${local.prefix}-sagemaker-ecr-deepar"
  role  = aws_iam_role.sagemaker[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "arn:aws:ecr:${var.aws_region}:462105765813:repository/forecasting-deepar*"
      }
    ]
  })
}