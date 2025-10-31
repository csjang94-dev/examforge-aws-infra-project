# environment (dev 또는 prd 환경 이름)
variable "environment" {
  description = "The environment name (e.g., dev, prd)"
  type        = string
}

# vpc_id (VPC 모듈에서 전달받은 VPC ID)
variable "vpc_id" {
  description = "The ID of the VPC to deploy resources into"
  type        = string
}

# public_subnet_ids (ALB 배치를 위한 Public Subnet ID 목록)
variable "public_subnet_ids" {
  description = "List of Public Subnet IDs for ALB"
  type        = list(string)
}

# private_subnet_ids (Fargate Task 배치를 위한 Private Subnet ID 목록)
variable "private_subnet_ids" {
  description = "List of Private Subnet IDs for ECS Tasks"
  type        = list(string)
}

# ecs_task_role_arn (DynamoDB 접근 권한을 가진 IAM 역할 ARN)
variable "ecs_task_role_arn" {
  description = "ARN of the IAM role for ECS Task (DynamoDB access)"
  type        = string
}

# AWS 리전 (로그 그룹 생성 등에서 필요)
variable "aws_region" {
  description = "The AWS region"
  type        = string
}

# ECR Repository URL (Task Definition에서 이미지 위치 지정용)
variable "ecr_repository_url" {
  description = "The URL of the ECR repository"
  type        = string
}


# modules/ecs-cluster/variables.tf
variable "existing_alb_certificate_arn" {
  description = "The ARN of the ACM certificate for ALB HTTPS listener (ap-northeast-2)."
  type        = string
}
