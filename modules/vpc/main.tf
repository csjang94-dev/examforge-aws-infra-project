# 1. VPC 생성
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }
}

# 2. Internet Gateway (IGW)
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
  }
}

# 3. Public Subnet (AZ별 1개)
resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true # Public IP 자동 할당

  tags = {
    Name        = "${var.environment}-public-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

# 4. Private Subnet (AZ별 1개)
resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name        = "${var.environment}-private-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

# 5. NAT Gateway용 Elastic IP (AZ별 1개)
resource "aws_eip" "nat" {
  count = var.create_nat_gateway ? length(var.availability_zones) : 0

  tags = {
    Name        = "${var.environment}-nat-eip-${count.index + 1}"
    Environment = var.environment
  }
}

# 6. NAT Gateway (AZ별 1개, Public Subnet에 위치)
resource "aws_nat_gateway" "nat" {
  count         = var.create_nat_gateway ? length(var.availability_zones) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  depends_on    = [aws_internet_gateway.gw]

  tags = {
    Name        = "${var.environment}-nat-gw-${count.index + 1}"
    Environment = var.environment
  }
}

# 7. Public Route Table (1개)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id # IGW로 라우팅
  }

  tags = {
    Name        = "${var.environment}-public-rt"
    Environment = var.environment
  }
}

# 8. 💡 Private Route Table (AZ별 1개 생성)
resource "aws_route_table" "private" {
  # AZ 개수만큼 Private Route Table 생성
  count = length(var.availability_zones) 
  
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    
    # 💡 [핵심] 동일한 AZ의 NAT Gateway로 라우팅 (e.g., nat[0] -> rt[0], nat[1] -> rt[1])
    nat_gateway_id = var.create_nat_gateway ? aws_nat_gateway.nat[count.index].id : null
  }

  tags = {
    Name        = "${var.environment}-private-rt-${count.index + 1}"
    Environment = var.environment
  }
}

# 9. Public Subnet <-> Public Route Table 연결
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# 10. 💡 Private Subnet <-> Private Route Table 연결 (AZ별 매칭)
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  
  # 💡 private_subnet[0] -> private_rt[0], private_subnet[1] -> private_rt[1]
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}