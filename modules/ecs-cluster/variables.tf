variable "environment" {
  description = "The environment name (e.g., dev, prd)"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC to deploy resources into"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of Public Subnet IDs for ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of Private Subnet IDs for ECS Tasks"
  type        = list(string)
}

variable "ecs_task_role_arn" {
  description = "ARN of the IAM role for ECS Task (DynamoDB access)"
  type        = string
}

variable "aws_region" {
  description = "The AWS region"
  type        = string
}

variable "existing_alb_certificate_arn" {
  description = "The ARN of the ACM certificate for ALB HTTPS listener"
  type        = string
}

variable "app_name" {
  description = "Application name for naming resources (e.g., examforge)."
  type        = string
}

variable "app_port" {
  description = "The container port the application listens on (e.g., 3000)."
  type        = number
  default     = 3000 # Node.js 기본 포트 가정
}

variable "task_cpu" {
  description = "The number of CPU units (e.g., 256 for 0.25 vCPU)."
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "The amount of memory (in MiB) to assign to the task (e.g., 512)."
  type        = number
  default     = 512
}

variable "app_image_tag" {
  description = "The tag of the Docker image to use (e.g., latest or a commit hash)."
  type        = string
  default     = "latest"
}