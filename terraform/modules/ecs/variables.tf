variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC"
}

variable "private_subnets" {
  type        = list(string)
  description = "List of private subnet IDs for the ECS tasks"
}

variable "alb_security_group_id" {
  type        = string
  description = "Security group ID of the ALB to allow inbound traffic"
}

variable "target_group_arn" {
  type        = string
  description = "ARN of the ALB target group"
}

variable "container_image" {
  type        = string
  description = "The URI of the container image in ECR"
}

variable "container_port" {
  type        = number
  default     = 3000
}

variable "aws_region" {
  type        = string
  default     = "us-east-1"
}
