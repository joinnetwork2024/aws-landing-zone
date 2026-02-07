output "role_arn" {
  description = "ARN of the created role"
  value       = aws_iam_role.this.arn
}

output "policy_arn" {
  description = "ARN of the least-privilege policy"
  value       = aws_iam_policy.least_privilege.arn
}