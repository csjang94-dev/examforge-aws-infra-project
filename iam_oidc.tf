# iam_oidc.tf

# 1. GitHub OIDC Provider (AWS에 이미 등록되어 있다고 가정)
data "aws_iam_openid_connect_provider" "github" {
  arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

# 2. GitHub Actions가 Assume Role 할 수 있는 신뢰 정책 (공통)
data "aws_iam_policy_document" "github_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }
    
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# 3. Dev 환경 배포용 IAM Role (💡 'dev' 브랜치와 연결)
resource "aws_iam_role" "github_actions_dev_role" {
  name = "github-actions-dev-deployer-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      for s in data.aws_iam_policy_document.github_assume_role_policy.statement : {
        Effect    = s.effect
        Action    = s.actions
        Principal = s.principals
        Condition = merge(s.condition, {
          "StringLike" = {
            # 💡 'dev' 브랜치에서만 Assume Role 허용
            "token.actions.githubusercontent.com:sub" = "repo:csjang94-dev/examforge-gjjang:ref:refs/heads/dev"
          }
        })
      }
    ]
  })
}

# 4. Prd 환경 배포용 IAM Role (💡 'prd' 브랜치와 연결)
resource "aws_iam_role" "github_actions_prd_role" {
  name = "github-actions-prd-deployer-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      for s in data.aws_iam_policy_document.github_assume_role_policy.statement : {
        Effect    = s.effect
        Action    = s.actions
        Principal = s.principals
        Condition = merge(s.condition, {
          "StringLike" = {
            # 💡 'prd' 브랜치에서만 Assume Role 허용
            "token.actions.githubusercontent.com:sub" = "repo:csjang94-dev/examforge-gjjang:ref:refs/heads/prd"
          }
        })
      }
    ]
  })
}

# 5. Dev/Prd Role에 AWS 관리형 정책 연결 (이전과 동일)
resource "aws_iam_role_policy_attachment" "dev_ecr" {
  role       = aws_iam_role.github_actions_dev_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "dev_ecs" {
  role       = aws_iam_role.github_actions_dev_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

resource "aws_iam_role_policy_attachment" "prd_ecr" {
  role       = aws_iam_role.github_actions_prd_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "prd_ecs" {
  role       = aws_iam_role.github_actions_prd_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}