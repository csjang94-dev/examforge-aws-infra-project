data "aws_region" "current" {}

# 1. ECS 클러스터 생성
resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-${var.environment}-cluster"
  tags = {
    Environment = var.environment
  }
}

# 2. ECR Repository 생성 (Docker 이미지 저장소)
resource "aws_ecr_repository" "app_repo" {
  name                 = "${var.app_name}/${var.environment}-repo"
  image_tag_mutability = "MUTABLE"

  tags = {
    Environment = var.environment
  }
}

# 3. CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.app_name}-${var.environment}"
  retention_in_days = 7
  tags = {
    Environment = var.environment
  }
}

# 4. ALB용 보안 그룹
resource "aws_security_group" "alb" {
  name        = "${var.app_name}-${var.environment}-alb-sg"
  description = "Allows HTTP/HTTPS traffic to the ALB"
  vpc_id      = var.vpc_id

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
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "${var.app_name}-${var.environment}-alb-sg"
    Environment = var.environment
  }
}

# 5. ECS Service (Fargate Task)용 보안 그룹
resource "aws_security_group" "ecs_service" {
  name        = "${var.app_name}-${var.environment}-ecs-sg"
  description = "Allows traffic only from ALB to ECS Tasks"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Access from ALB"
    from_port       = var.app_port # 80이 아닌 앱 포트(e.g., 3000)
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "${var.app_name}-${var.environment}-ecs-sg"
    Environment = var.environment
  }
}

# 6. Application Load Balancer (ALB)
resource "aws_lb" "main" {
  name               = "${var.app_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  tags = {
    Environment = var.environment
  }
}

# 7. ALB Target Group
resource "aws_lb_target_group" "app" {
  name        = "${var.app_name}-${var.environment}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/" # 헬스 체크 경로
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  tags = {
    Name        = "${var.app_name}-${var.environment}-tg"
    Environment = var.environment
  }
}

# 8. ALB Listener (HTTPS - 443)
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.existing_alb_certificate_arn
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# 9. ALB Listener (HTTP - 80) -> HTTPS 리다이렉트
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# 10. ECS Task Execution Role (ECR 접근, CloudWatch 로그 전송용)
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.app_name}-${var.environment}-ecs-exec-role"

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

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 11. ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.app_name}-${var.environment}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory

  # 💡 [핵심 수정] 루트 모듈에서 전달받은 Task Role ARN (DynamoDB 접근 권한 O)
  task_role_arn = var.ecs_task_role_arn

  # 모듈 내에서 생성한 Execution Role ARN (ECR 접근 권한 O)
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "app-container",
      # 모듈 내에서 생성한 ECR 리포지토리 사용
      image     = "${aws_ecr_repository.app_repo.repository_url}:${var.app_image_tag}", 
      essential = true,
      portMappings = [
        {
          containerPort = var.app_port,
          hostPort      = var.app_port
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name,
          "awslogs-region"        = data.aws_region.current.name,
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Environment = var.environment
  }
}

# 12. ECS Service
resource "aws_ecs_service" "app" {
  name            = "${var.app_name}-${var.environment}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"
  desired_count   = 2 # 고가용성을 위해 최소 2개

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.ecs_service.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app-container"
    container_port   = var.app_port
  }

  # Task Definition이 변경될 때 롤링 업데이트 보장
  lifecycle {
    ignore_changes = [task_definition]
  }
  
  # 서비스가 ALB에 정상 등록될 때까지 기다림
  depends_on = [aws_lb_listener.https]
}