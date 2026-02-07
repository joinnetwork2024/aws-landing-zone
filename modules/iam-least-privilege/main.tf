locals {
  # Pre-defined least-privilege actions per service (AI/ML focused)
  service_actions = {
    s3         = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
    cloudwatch = ["cloudwatch:PutMetricData", "logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    sagemaker  = [
      "sagemaker:CreateNotebookInstance",
      "sagemaker:StartNotebookInstance",
      "sagemaker:StopNotebookInstance",
      "sagemaker:DescribeNotebookInstance",
      "sagemaker:ListTags",
      "sagemaker:AddTags"
      # Explicitly NO CreateTrainingJob, CreateEndpoint, etc.
    ]
    ecr        = ["ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage", "ecr:BatchCheckLayerAvailability"]
    bedrock    = ["bedrock:ListFoundationModels", "bedrock:InvokeModel"] # inference-only
  }

  allowed_actions = distinct(flatten([
    for svc in var.allowed_services : lookup(local.service_actions, svc, [])
  ]))
}

# Trust policy – scoped to environment tag
data "aws_iam_policy_document" "assume" {
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "AWS"
      identifiers = var.trusted_principal_arns
    }
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalTag/environment"
      values   = [var.environment]
    }
  }
}

resource "aws_iam_role" "this" {
  name                 = "${var.role_name}-${var.environment}"
  assume_role_policy   = data.aws_iam_policy_document.assume.json
  permissions_boundary = aws_iam_policy.boundary.arn
  max_session_duration = 43200 # 12 hours max
  tags                 = merge(var.resource_tags, { Environment = var.environment, RoleType = var.role_name })
}

# Dynamic least-privilege policy + explicit denies for AI risks
data "aws_iam_policy_document" "least_privilege" {
  dynamic "statement" {
    for_each = length(local.allowed_actions) > 0 ? [1] : []
    content {
      effect    = "Allow"
      actions   = local.allowed_actions
      resources = ["*"]  # In production, replace with specific ARNs via additional var
    }
  }

  # Explicit denies for AI/ML high-risk actions (cost & security)
  statement {
    sid       = "DenyExpensiveOrRiskyAI"
    effect    = "Deny"
    actions   = [
      "sagemaker:CreateTrainingJob",
      "sagemaker:CreateProcessingJob",
      "sagemaker:CreateHyperParameterTuningJob",
      "sagemaker:CreateEndpoint",
      "sagemaker:CreateEndpointConfig",
      "ec2:RunInstances"  # blocks accidental GPU spin-up
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "least_privilege" {
  name   = "${var.role_name}-least-privilege-${var.environment}"
  policy = data.aws_iam_policy_document.least_privilege.json
}

resource "aws_iam_role_policy_attachment" "least_privilege" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.least_privilege.arn
}

# Permissions boundary – hard ceiling
data "aws_iam_policy_document" "boundary" {
  # DENY high-risk actions at boundary level (applies to all IAM entities)
  statement {
    sid    = "DenyGlobalRiskyActions"
    effect = "Deny"
    actions = [
      "iam:*", "organizations:*", "account:*",
      "cloudtrail:*", "config:*", "guardduty:*"  # Security services
    ]
    resources = ["*"]
  }
  
  statement {
    sid    = "DenyExpensiveResources"
    effect = "Deny"
    actions = [

      "ec2:RequestSpotInstances"  # Spot fleet can get expensive
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "boundary" {
  name   = "AI-LeastPrivilege-Boundary-${var.environment}"
  description = "Permissions boundary for AI/ML roles — controlled PassRole, no escalation"
  policy = data.aws_iam_policy_document.boundary.json
  
}