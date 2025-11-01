output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_lb.main.dns_name
}

output "ecr_repository_url" {
  description = "The URL of the ECR repository created for this environment"
  value       = aws_ecr_repository.app_repo.repository_url
}

output "cluster_arn" {
  description = "The ARN of the ECS Cluster"
  value       = aws_ecs_cluster.main.arn
}