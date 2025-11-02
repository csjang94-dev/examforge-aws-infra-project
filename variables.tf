variable "aws_region" {
  description = "The AWS region to deploy resources into."
  type        = string
  default     = "ap-northeast-2"
}

variable "tf_backend_bucket_name" {
  description = "The S3 bucket name used to store the Terraform state file."
  type        = string
  # default = "my-terraform-backend-bucket" # tfvars 또는 CI/CD 변수로 설정 권장
}

variable "existing_alb_certificate_arn" {
  description = "The ARN of the ACM certificate for ALB Listener (MUST BE in ap-northeast-2)."
  type        = string
  default     = "arn:aws:acm:ap-northeast-2:140023399909:certificate/bfcf784f-d07a-49f7-ab6f-7e7e8edb7f62"
}

# 참고: CloudFront용 ACM ARN은 이 모듈에서 직접 사용되지 않으므로 제거 (필요시 S3 모듈 등에서 사용)
# variable "existing_cloudfront_certificate_arn" { ... }

variable "root_domain_name" {
  description = "The root domain name hosted in Route 53 (e.g., project-gjjang.com)."
  type        = string
  default     = "project-gjjang.com"
}