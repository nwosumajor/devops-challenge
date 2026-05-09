# terraform/main.tf

# 1. Elastic Container Registry (ECR)
resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}-repo"
  image_tag_mutability = "MUTABLE"
  force_delete         = true # Ensures easy cleanup when you destroy the challenge

  image_scanning_configuration {
    scan_on_push = true
  }
}

# 2. Networking Module
module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
}

# 3. Application Load Balancer Module
module "alb" {
  source         = "./modules/alb"
  project_name   = var.project_name
  vpc_id         = module.networking.vpc_id
  public_subnets = module.networking.public_subnets
}

# 4. ECS Fargate Module
module "ecs" {
  source                = "./modules/ecs"
  project_name          = var.project_name
  vpc_id                = module.networking.vpc_id
  private_subnets       = module.networking.private_subnets
  alb_security_group_id = module.alb.alb_security_group_id
  target_group_arn      = module.alb.target_group_arn
  container_port        = var.container_port
  
  # We point ECS directly to the ECR repo we just created, looking for the "latest" tag
  container_image       = "${aws_ecr_repository.app.repository_url}:latest"
}
# 5. GitHub OIDC Provider (Tells AWS to trust GitHub Actions)
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # Standard GitHub thumbprint
}

# 6. IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions_role" {
  name = "${var.project_name}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Condition = {
        StringLike = {
          # Restrict this role ONLY to your specific GitHub repository
          "token.actions.githubusercontent.com:sub": "repo:nwosumajor/devops-challenge:*"
        }
        StringEquals = {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        }
      }
    }]
  })
}

# 7. Grant the GitHub Actions Role permission to push to ECR and update ECS
resource "aws_iam_role_policy" "github_actions_policy" {
  name = "${var.project_name}-github-actions-policy"
  role = aws_iam_role.github_actions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices"
        ]
        Resource = module.ecs.service_arn # Assumes you added this output in the ECS module
      }
    ]
  })
}
# 8. Monitoring Module
module "monitoring" {
  source       = "./modules/monitoring"
  project_name = var.project_name
  cluster_name = module.ecs.cluster_name
  service_name = module.ecs.service_name
}
