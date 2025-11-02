# Dev 환경 DynamoDB 테이블
resource "aws_dynamodb_table" "user_data_dev" {
  name         = "User-Data-Dev"
  billing_mode = "PAY_PER_REQUEST" # 서버리스 방식으로 비용 효율적
  hash_key     = "UserID"
  
  attribute {
    name = "UserID"
    type = "S"
  }
  
  tags = {
    Environment = "dev"
  }
}

# Prd 환경 DynamoDB 테이블
resource "aws_dynamodb_table" "user_data_prd" {
  name           = "prd-user-data"
  hash_key       = "UserId"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "UserId"
    type = "S"
  }
  
  tags = {
    Environment = "prd"
  }
}