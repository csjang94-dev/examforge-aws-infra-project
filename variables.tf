variable "aws_region" {
  description = "The AWS region to deploy resources into."
  type        = string
  default     = "ap-northeast-2"
}

variable "aws_account_id" {
  description = "Your AWS Account ID."
  type        = string
}

variable "tf_backend_bucket_name" {
  description = "The S3 bucket name used to store the Terraform state file."
  type        = string
}

# variables.tf 파일에 추가

variable "existing_cloudfront_certificate_arn" {
  description = "The ARN of the ACM certificate for CloudFront CDN (MUST BE in us-east-1)."
  type        = string
  # 💡 여기에 기본값 (default)을 넣거나, terraform.tfvars에 값을 정의해야 합니다.
  default     = "arn:aws:acm:us-east-1:140023399909:certificate/5aefe80c-bee9-4481-9946-520e4dbb5726" 
}

# 💡 ALB용 (ap-northeast-2 ARN) - 방금 알려주신 값
variable "existing_alb_certificate_arn" {
  description = "The ARN of the ACM certificate for ALB Listener (MUST BE in ap-northeast-2)."
  type        = string
  default     = "arn:aws:acm:ap-northeast-2:140023399909:certificate/bfcf784f-d07a-49f7-ab6f-7e7e8edb7f62" 
}

variable "root_domain_name" {
  description = "The root domain name hosted in Route 53 (e.g., project-gjjang.com)."
  type        = string
  default     = "project-gjjang.com"
}

variable "dev_ecr_image_url" {
  description = "The ECR image URL for the development environment (including tag)."
  type        = string
}

variable "prd_ecr_image_url" {
  description = "The ECR image URL for the production environment (including tag)."
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, prd)"
  type        = string
  default     = "dev" # 💡 'dev'를 기본값으로 지정하여 입력 요청 생략
}

