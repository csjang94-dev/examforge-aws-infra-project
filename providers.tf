terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Backend (S3 + DynamoDB Locking) 설정은 별도 구성 필요
  # backend "s3" {
  #   bucket         = "your-tf-state-bucket" # var.tf_backend_bucket_name 사용 불가
  #   key            = "global/terraform.tfstate"
  #   region         = "ap-northeast-2"
  #   dynamodb_table = "your-tf-lock-table"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region
}

# 공통 데이터 소스
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}