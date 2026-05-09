# terraform/variables.tf

variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project used for tagging and resource naming"
  type        = string
  default     = "devops-challenge"
}

variable "container_port" {
  description = "The port the container listens on"
  type        = number
  default     = 3000
}
