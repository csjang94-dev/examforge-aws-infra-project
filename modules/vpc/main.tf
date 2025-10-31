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

# 2. Internet Gateway (IGW) - Public 통신 허용
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
  }
}

# 3. Public Subnet 정의 (2개 AZ)
resource "aws_subnet" "public" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  map_public_ip_on_launch = true # Public IP 자동 할당

  tags = {
    Name        = "${var.environment}-public-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

# 4. Private Subnet 정의 (2개 AZ)
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

# 5. NAT Gateway (Private Subnet의 아웃바운드 통신 허용)
resource "aws_eip" "nat" {
  count      = var.create_nat_gateway ? length(var.availability_zones) : 0

  tags = {
    Name = "${var.environment}-nat-eip-${count.index + 1}"
    Environment = var.environment # Environment 태그를 포함하여 명확성을 높입니다.
  }
}

resource "aws_nat_gateway" "nat" {
  count         = var.create_nat_gateway ? length(var.availability_zones) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  depends_on    = [aws_internet_gateway.gw]

  tags = {
    Name = "${var.environment}-nat-gw-${count.index + 1}"
  }
}


# ----------------------------------------------------
# 3. Public Route Table (인터넷 게이트웨이로 연결)
# ----------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id # 모든 외부 트래픽을 IGW로 보냄
  }

  tags = {
    Name        = "${var.environment}-public-rt"
    Environment = var.environment
  }
}

# 4. Private Route Table (NAT Gateway로 연결)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    # 💡 중요: NAT GW가 생성된 경우에만 라우팅을 설정합니다.
    nat_gateway_id = var.create_nat_gateway ? aws_nat_gateway.nat[0].id : null 
  }

  tags = {
    Name        = "${var.environment}-private-rt"
    Environment = var.environment
  }
}


# ----------------------------------------------------
# 5. Route Table Association (서브넷과 테이블 연결)
# ----------------------------------------------------
# Public Subnets을 Public Route Table과 연결
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Subnets을 Private Route Table과 연결
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
