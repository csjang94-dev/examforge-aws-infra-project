# GitHub OIDC Provider는 AWS에 이미 등록되어 있으므로 데이터 소스로 가져옵니다.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# 1. GitHub Actions가 Assume Role 할 수 있는 IAM Role 정의
# 이 Role은 ECR에 푸시하고 ECS 서비스를 업데이트할 권한을 가집니다.
resource "aws_iam_role" "github_actions_deployer" {
  name               = "${var.environment}-github-deployer-role"
  assume_role_policy = data.aws_iam_policy_document.github_assume.json
}

# 2. Role을 GitHub 저장소에 위임하기 위한 Trust Policy (신뢰 관계)
data "aws_iam_policy_document" "github_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      # OIDC Audience는 sts.amazonaws.com으로 고정
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      # 💡 사용자님의 저장소 경로를 지정합니다. (csjang94-dev/examforge-gjjang)
      # main 브랜치에서만 배포 Role을 맡도록 제한
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:csjang94-dev/examforge-gjjang:ref:refs/heads/main"]
    }
  }
}

# 3. Role에 AWS 권한 부여 (ECR 접근 및 ECS 배포 권한)
resource "aws_iam_role_policy_attachment" "deployer_policy_ecr" {
  role       = aws_iam_role.github_actions_deployer.name
  # ECR Push/Pull 권한 정책
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "deployer_policy_ecs" {
  role       = aws_iam_role.github_actions_deployer.name
  # ECS Deploy 권한 정책 (Task Definition 및 Service 업데이트 권한 포함)
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess" 
}

# 4. GitHub Actions가 Assume 할 Role ARN을 출력
output "github_deploy_role_arn" {
  value = aws_iam_role.github_actions_deployer.arn
}

