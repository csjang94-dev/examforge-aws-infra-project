# 1. Dev 환경 VPC 구축
module "dev_vpc" {
  source = "./modules/vpc"

  environment          = "dev"
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["ap-northeast-2a"]
  public_subnet_cidrs  = ["10.0.1.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24"]
  create_nat_gateway   = true
}

# 2. Prd 환경 VPC 구축
module "prd_vpc" {
  source = "./modules/vpc"

  environment          = "prd"
  vpc_cidr             = "10.1.0.0/16"
  availability_zones   = ["ap-northeast-2a", "ap-northeast-2b"]
  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs = ["10.1.11.0/24", "10.1.12.0/24"]
  create_nat_gateway   = true
}

# 3. 정적 웹사이트 S3 버킷 구축 (신규 모듈 호출)
module "static_site" {
  source      = "./modules/s3-static-site"
  bucket_name = "aws-quiz-static-content-${var.aws_region}-${data.aws_caller_identity.current.account_id}"
}

# 4. Dev 환경 ECS 클러스터, ALB 등 구축
module "dev_ecs" {
  source = "./modules/ecs-cluster"

  app_name           = "examforge"
  environment        = "dev"
  vpc_id             = module.dev_vpc.vpc_id
  public_subnet_ids  = module.dev_vpc.public_subnet_ids
  private_subnet_ids = module.dev_vpc.private_subnet_ids

  # iam_ecs.tf에서 생성한 역할(DynamoDB 접근 권한) 전달
  ecs_task_role_arn = aws_iam_role.dev_ecs_task_role.arn

  existing_alb_certificate_arn = var.existing_alb_certificate_arn
  aws_region                   = var.aws_region
  
  # app_image_tag는 CI/CD 시점에 변수로 주입하거나 terraform.tfvars에 정의
  # app_image_tag = "latest" 
}

# 5. Prd 환경 ECS 클러스터, ALB 등 구축
module "prd_ecs" {
  source = "./modules/ecs-cluster"

  app_name           = "examforge"
  environment        = "prd"
  vpc_id             = module.prd_vpc.vpc_id
  public_subnet_ids  = module.prd_vpc.public_subnet_ids
  private_subnet_ids = module.prd_vpc.private_subnet_ids
  
  # iam_ecs.tf에서 생성한 역할(DynamoDB 접근 권한) 전달
  ecs_task_role_arn = aws_iam_role.prd_ecs_task_role.arn

  existing_alb_certificate_arn = var.existing_alb_certificate_arn
  aws_region                   = var.aws_region
  
  # app_image_tag = "stable"
}

# 6. DynamoDB VPC Endpoint (Private Subnet에서 안전한 DB 접근 보장)
locals {
  target_vpcs = [module.dev_vpc, module.prd_vpc]
}

resource "aws_vpc_endpoint" "dynamodb" {
  count = length(local.target_vpcs)

  vpc_id            = local.target_vpcs[count.index].vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.id}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = local.target_vpcs[count.index].private_route_table_ids

  tags = {
    Name = "DynamoDB-VPC-Endpoint-${local.target_vpcs[count.index].vpc_id}"
  }
}