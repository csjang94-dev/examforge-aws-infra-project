# modules/vpc/outputs.tf 파일 내용

# VPC ID 출력
output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.main.id
}

# Public Subnet ID 목록 출력
output "public_subnet_ids" {
  description = "List of Public Subnet IDs."
  # aws_subnet.public 리소스가 목록으로 생성되었기 때문에 [*].id를 사용합니다.
  value       = aws_subnet.public[*].id
}

# Private Subnet ID 목록 출력
output "private_subnet_ids" {
  description = "List of Private Subnet IDs."
  value       = aws_subnet.private[*].id
}

# Private Route Table ID 목록 출력 (DynamoDB Endpoint 연결용)
output "private_route_table_ids" {
  description = "IDs of the private route tables."
  value       = aws_route_table.private[*].id # 또는 다른 적절한 참조
}
