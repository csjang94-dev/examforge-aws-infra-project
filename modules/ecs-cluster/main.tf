# 1. ECS 클러스터 생성 (환경별 격리)
resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-cluster"
  tags = {
    Environment = var.environment
  }
}

# 2. ECR Repository 생성 (Docker 이미지 저장소)
resource "aws_ecr_repository" "app_repo" {
  name                 = "${var.environment}/app-repo"
  image_tag_mutability = "MUTABLE"

  tags = {
    Environment = var.environment
  }
}

# modules/ecs-cluster/main.tf 파일에 추가

# ----------------------------------------------------
# 1. ALB용 보안 그룹 (외부 트래픽 허용)
# ----------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg"
  description = "Allows HTTP/HTTPS traffic to the ALB"
  vpc_id      = var.vpc_id # VPC ID는 main.tf에서 변수로 전달받음

  # Ingress (인바운드): HTTP 및 HTTPS 트래픽 허용
  ingress {
    description = "HTTP access from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS access from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress (아웃바운드): 모든 외부 통신 허용 (NAT GW를 통해 나감)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-alb-sg"
    Environment = var.environment
  }
}

# ----------------------------------------------------
# 2. ECS Service (Fargate Task)용 보안 그룹 (ALB 트래픽만 허용)
# ----------------------------------------------------
resource "aws_security_group" "ecs_service" {
  name        = "${var.environment}-ecs-sg"
  description = "Allows traffic only from ALB to ECS Tasks"
  vpc_id      = var.vpc_id

  # Ingress (인바운드): 해당 환경의 ALB (보안 그룹)에서 오는 트래픽만 80번 포트로 허용
  ingress {
    description     = "Access from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id] # 💡 ALB의 SG ID 참조
  }

  # Egress (아웃바운드): 모든 외부 통신 허용 (DB 접근 및 외부 API 호출용)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-ecs-sg"
    Environment = var.environment
  }
}


# 3. Application Load Balancer (ALB)
resource "aws_lb" "main" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids # Public Subnet에 배치

  tags = {
    Environment = var.environment
  }
}

# modules/ecs-cluster/main.tf 파일에 추가

# ----------------------------------------------------
# 1. ALB Target Group (대상 그룹) 정의
# ----------------------------------------------------
# ECS 서비스의 컨테이너로 트래픽을 전달하고, 상태를 확인합니다.
resource "aws_lb_target_group" "app" {
  name     = "${var.environment}-app-tg"
  port     = 80 # 컨테이너가 노출하는 포트 (앱 포트)
  protocol = "HTTP"
  vpc_id   = var.vpc_id # 모듈로 전달받은 VPC ID

  # Fargate 사용 시 필수 설정
  target_type = "ip"
  
  # 헬스 체크 설정
  health_check {
    path                = "/" # 애플리케이션의 헬스 체크 경로 (필요 시 수정)
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.environment}-app-tg"
    Environment = var.environment
  }
}

# ----------------------------------------------------
# 2. ALB Listener (수신기) 정의 - HTTPS (443)
# ----------------------------------------------------
# 외부 트래픽을 443 포트로 받아 Target Group으로 전달합니다.
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  
  # 💡 ALB용 (ap-northeast-2) ARN 연결
  certificate_arn   = var.existing_alb_certificate_arn 

  # 필수 보안 정책
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# ----------------------------------------------------
# 3. ALB Listener (수신기) 정의 - HTTP to HTTPS 리다이렉트 (선택 사항)
# ----------------------------------------------------
# 80 포트로 들어오는 모든 HTTP 요청을 443 HTTPS로 리다이렉트합니다.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# 6. ECS Task Execution Role (ECS가 AWS 리소스를 관리하기 위한 권한)
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.environment}-ecs-exec-role"

  # ECS 서비스 신뢰 정책
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

# ECS Task 실행 시 필요한 관리형 정책 연결 (ECR 접근, CloudWatch 로그 등)
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 7. ECS Service (Fargate Task 실행 및 관리)
resource "aws_ecs_service" "app" {
  name            = "${var.environment}-app-service"
  cluster         = aws_ecs_cluster.main.id
  launch_type     = "FARGATE" # 서버 관리가 필요 없는 Fargate 사용
  desired_count   = 2 # 최소 2개의 Task 실행 (고가용성)

  # Private Subnet에서 실행되도록 네트워크 구성
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app-container" # 컨테이너 이름 (Dockerfile에서 정의)
    container_port   = 80 
  }

  # Task Definition (컨테이너 이미지, CPU/메모리, 환경 변수 등 상세 설정)은 
  # 서비스 배포 시 GitHub Actions/CodeDeploy에 의해 업데이트되는 것이 일반적이므로,
  # 여기서는 최소한의 정의만 포함하거나 별도 모듈로 분리할 수 있습니다. 
  # (이 예시에서는 간결함을 위해 생략하고, 다음 단계에서 Task Definition을 추가합니다.)
  
  # ... (Task Definition 코드가 여기에 추가됩니다.)
  
  # 9. ECS Service에 Task Definition 연결 업데이트
  # Task Definition ARN 연결
  task_definition = aws_ecs_task_definition.app.arn
}

# (modules/ecs-cluster/main.tf 파일에 추가)

# 8. ECS Task Definition (컨테이너 실행 명세)
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.environment}-app-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512    # CPU 유닛 (0.5 vCPU)
  memory                   = 1024   # 메모리 (1GB)

  # Task 실행 역할 (DynamoDB 접근 권한을 가진 역할 연결)
  task_role_arn            = var.ecs_task_role_arn

  # Task 실행 역할 (ECR 접근, 로그 전송 권한을 가진 역할 연결)
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn 

  container_definitions = jsonencode([
    {
      name      = "app-container"
      image     = "${var.ecr_repository_url}:latest" # ECR 리포지토리 URL
      cpu       = 512
      memory    = 1024
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.environment}-app"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Environment = var.environment
  }
}


