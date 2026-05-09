output "service_arn" {
  value       = aws_ecs_service.main.id
  description = "The ARN of the ECS service"
}
output "cluster_name" {
  value       = aws_ecs_cluster.main.name
  description = "The name of the ECS cluster"
}

output "service_name" {
  value       = aws_ecs_service.main.name
  description = "The name of the ECS service"
}
