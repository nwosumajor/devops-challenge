output "alb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "The public DNS name of the load balancer"
}

output "target_group_arn" {
  value       = aws_lb_target_group.app.arn
  description = "The ARN of the target group for ECS to attach to"
}

output "alb_security_group_id" {
  value       = aws_security_group.alb.id
  description = "The ID of the ALB security group"
}
