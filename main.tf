data "aws_region" "current" {}

# Backend (S3 + DynamoDB Locking) 설정은 별도 구성 필요

# 1. Dev 환경 VPC 구축
module "dev_vpc" {
  source = "./modules/vpc"

  environment = "dev"
  vpc_cidr    = "10.0.0.0/16"

  # Dev 환경에서는 NAT Gateway를 1개만 생성하여 비용 절감 (선택 사항)
  availability_zones  = ["ap-northeast-2a", "ap-northeast-2b"] 
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  create_nat_gateway = true 
}

# 2. Prd 환경 VPC 구축
module "prd_vpc" {
  source = "./modules/vpc"

  environment = "prd"
  vpc_cidr    = "10.1.0.0/16"

  # Prd 환경에서는 고가용성을 위해 NAT Gateway를 2개 생성 (각 AZ에 1개씩)
  availability_zones  = ["ap-northeast-2a", "ap-northeast-2b"]
  public_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs = ["10.1.11.0/24", "10.1.12.0/24"]
  create_nat_gateway = true 
}

# 3. DynamoDB 테이블 (공유 리소스이므로 여기서 정의)
resource "aws_dynamodb_table" "user_data_dev" {
  name           = "User-Data-Dev"
  billing_mode   = "PAY_PER_REQUEST" # 서버리스 방식으로 비용 효율적
  hash_key       = "UserID"
  attribute {
    name = "UserID"
    type = "S"
  }
  tags = {
    Environment = "dev"
  }
}

resource "aws_dynamodb_table" "user_data_prd" {
  name             = "prd-user-data"
  hash_key         = "UserId"
  billing_mode     = "PROVISIONED"
  read_capacity    = 5
  write_capacity   = 5

  attribute {
    name = "UserId"
    type = "S"
  }
  tags = {
    Environment = "prd"
  }
}

# ... (VPC 모듈 호출 및 DynamoDB 테이블 정의 코드는 이전 답변 참조)

# 1. Dev 환경 ECS 클러스터, ALB 등 구축
module "dev_ecs" {
  source = "./modules/ecs-cluster"

  environment        = "dev"
  vpc_id             = module.dev_vpc.vpc_id
  public_subnet_ids  = module.dev_vpc.public_subnet_ids
  private_subnet_ids = module.dev_vpc.private_subnet_ids

  # Dev 환경 ECS 클러스터, ALB 등 구축
  ecs_task_role_arn  = aws_iam_role.dev_ecs_task_role.arn

  # 💡 ACM ARN 변수 전달
  existing_alb_certificate_arn = var.existing_alb_certificate_arn  

  # ⭐ 추가해야 할 필수 변수들
  aws_region         = var.aws_region 
  ecr_repository_url = var.dev_ecr_image_url
}

# 2. Prd 환경 ECS 클러스터, ALB 등 구축
module "prd_ecs" {
  source = "./modules/ecs-cluster"

  environment        = "prd"
  vpc_id             = module.prd_vpc.vpc_id
  public_subnet_ids  = module.prd_vpc.public_subnet_ids
  private_subnet_ids = module.prd_vpc.private_subnet_ids

  # Prd 환경 ECS 클러스터, ALB 등 구축
  ecs_task_role_arn  = aws_iam_role.prd_ecs_task_role.arn

  # 💡 ACM ARN 변수 전달
  existing_alb_certificate_arn = var.existing_alb_certificate_arn

  # ⭐ 추가해야 할 필수 변수들
  aws_region         = var.aws_region 
  ecr_repository_url = var.prd_ecr_image_url
}

# 3. DynamoDB VPC Endpoint (Private Subnet에서 안전한 DB 접근 보장)
# Dev/Prd 모두 동일한 Endpoint를 사용하도록 정의 (Gateway Type)

# 💡 Dev와 Prd 모듈의 목록을 locals에 정의합니다.
locals {
  target_vpcs = [module.dev_vpc, module.prd_vpc]
}

resource "aws_vpc_endpoint" "dynamodb" {
  # 💡 이 줄만 남기고 중복된 count 정의는 삭제합니다.
  count             = length(local.target_vpcs) 

  vpc_id            = local.target_vpcs[count.index].vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.id}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = local.target_vpcs[count.index].private_route_table_ids

  tags = {
    Name = "DynamoDB-VPC-Endpoint"
  }
}

# 1. ECR 푸시 및 ECS 업데이트를 위한 IAM 정책 정의
resource "aws_iam_policy" "github_actions_policy" {
  name        = "GitHubActionsPolicy"
  description = "Policy for GitHub Actions CI/CD pipeline"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # ECR 관련 권한 (로그인, 이미지 푸시/풀)
      {
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ],
        Effect   = "Allow",
        Resource = "*" # ECR 권한은 일반적으로 전체 리소스(*)로 설정
      },
      # ECS 서비스 업데이트 권한 (CodeDeploy를 사용하지 않는 직접 업데이트 시 필요)
      {
        Action = [
          "ecs:DescribeServices",
          "ecs:UpdateService",
          "ecs:ListTasks"
        ],
        Effect   = "Allow",
        Resource = "*" # 실제 운영 시에는 dev/prd 클러스터 ARN으로 제한해야 함
      },
      # S3 Backend 접근 권한 (상태 파일 관리)
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Effect   = "Allow",
        Resource = [
          "arn:aws:s3:::${var.tf_backend_bucket_name}", # S3 버킷 ARN
          "arn:aws:s3:::${var.tf_backend_bucket_name}/*"
        ]
      }
    ]
  })
}

# 2. GitHub Actions CI/CD를 위한 IAM 사용자 생성
resource "aws_iam_user" "github_actions_user" {
  name = "github-actions-ci-user"
  tags = {
    Environment = "CI/CD"
  }
}

# 3. IAM 사용자에게 정책 연결
resource "aws_iam_user_policy_attachment" "github_actions_attach" {
  user       = aws_iam_user.github_actions_user.name
  policy_arn = aws_iam_policy.github_actions_policy.arn
}

# 4. Access Key 생성 (GitHub Secrets에 저장할 자격 증명)
resource "aws_iam_access_key" "github_actions_key" {
  user = aws_iam_user.github_actions_user.name
}

# 5. Access Key 출력을 통해 Secret 변수 준비
output "github_actions_aws_access_key_id" {
  value     = aws_iam_access_key.github_actions_key.id
  sensitive = true # 중요: 콘솔에 노출되지 않도록 설정
}

output "github_actions_aws_secret_access_key" {
  value     = aws_iam_access_key.github_actions_key.secret
  sensitive = true # 중요: 콘솔에 노출되지 않도록 설정
}

# main.tf 파일에 추가

# S3 웹사이트 정책 정의 (퍼블릭 읽기 허용)
data "aws_iam_policy_document" "s3_policy" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      aws_s3_bucket.static_content.arn,
      "${aws_s3_bucket.static_content.arn}/*",
    ]
  }
}

# 1. DynamoDB 접근을 위한 ECS Task Policy 정의
resource "aws_iam_policy" "ecs_dynamodb_access" {
  name        = "ECSDynamoDBAccessPolicy"
  description = "Allows ECS Tasks to read/write to specific DynamoDB tables"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:UpdateItem"
        ],
        Effect   = "Allow",
        # Dev와 Prd 테이블에 대한 접근 권한을 명시적으로 부여합니다.
        Resource = [
          aws_dynamodb_table.user_data_dev.arn,
          aws_dynamodb_table.user_data_prd.arn
        ]
      },
      # 추가: DynamoDB 인덱스 사용을 위한 권한 (필요 시)
      {
        Action   = "dynamodb:DescribeTable",
        Effect   = "Allow",
        Resource = [
          aws_dynamodb_table.user_data_dev.arn,
          aws_dynamodb_table.user_data_prd.arn
        ]
      }
    ]
  })
}

# 2. DynamoDB 접근 정책에 대한 Dev ECS Task Role 정의
resource "aws_iam_role" "dev_ecs_task_role" {
  name = "dev-ecs-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# 3. DynamoDB 접근 정책에 대한 Prd ECS Task Role 정의
resource "aws_iam_role" "prd_ecs_task_role" {
  name = "prd-ecs-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}


# 4. Dev/Prd Task Role에 DynamoDB 접근 정책 연결
resource "aws_iam_role_policy_attachment" "dev_dynamodb_attach" {
  role       = aws_iam_role.dev_ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_dynamodb_access.arn
}

resource "aws_iam_role_policy_attachment" "prd_dynamodb_attach" {
  role       = aws_iam_role.prd_ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_dynamodb_access.arn
}

# (main.tf 파일에서 ECS 모듈 호출 부분 업데이트)
  

# 1. 정적 웹사이트 콘텐츠를 저장할 S3 버킷 생성
resource "aws_s3_bucket" "static_content" {
  bucket = "aws-quiz-static-content-bucket-${var.aws_region}" # 버킷 이름은 전역적으로 고유해야 함

  tags = {
    Name = "Static Content Storage"
  }
}


# 2. S3 버킷에 대한 Public Access 차단 설정 (보안 강화)
resource "aws_s3_bucket_public_access_block" "static_content_block" {
  bucket                  = aws_s3_bucket.static_content.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}


resource "aws_s3_bucket_policy" "static_content_policy" {
  bucket = aws_s3_bucket.static_content.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

# main.tf 파일에 추가/수정

# 새로운 리소스 추가
resource "aws_s3_bucket_versioning" "static_content_versioning" {
  bucket = aws_s3_bucket.static_content.id
  versioning_configuration {
    status = "Enabled"
  }
}

# main.tf 파일에 추가 (필요한 경우)

resource "aws_s3_bucket_website_configuration" "static_content_website" {
  bucket = aws_s3_bucket.static_content.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}
