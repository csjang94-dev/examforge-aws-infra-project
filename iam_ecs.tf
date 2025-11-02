# 1. DynamoDB 접근을 위한 ECS Task Policy 정의
resource "aws_iam_policy" "ecs_dynamodb_access" {
  name        = "ECSDynamoDBAccessPolicy-ExamForge"
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
        Effect = "Allow",
        # Dev와 Prd 테이블에 대한 접근 권한을 명시적으로 부여합니다.
        Resource = [
          aws_dynamodb_table.user_data_dev.arn,
          aws_dynamodb_table.user_data_prd.arn
        ]
      },
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

# 2. Dev ECS Task Role 정의
resource "aws_iam_role" "dev_ecs_task_role" {
  name = "dev-ecs-task-role-examforge"
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

# 3. Prd ECS Task Role 정의
resource "aws_iam_role" "prd_ecs_task_role" {
  name = "prd-ecs-task-role-examforge"
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