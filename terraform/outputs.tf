# terraform/outputs.tf

output "ecr_repository_url" {
  value       = aws_ecr_repository.app.repository_url
  description = "The URL of the ECR repository"
}

output "application_url" {
  value       = "http://${module.alb.alb_dns_name}"
  description = "The public URL of your Load Balancer"
}
output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions_role.arn
  description = "The ARN of the IAM role for GitHub Actions to assume"
}
