variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC"
}

variable "public_subnets" {
  type        = list(string)
  description = "List of public subnet IDs for the ALB"
}
