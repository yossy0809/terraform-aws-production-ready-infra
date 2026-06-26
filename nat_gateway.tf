# ==========================================
# NAT Gateway
# ==========================================
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "portfolio-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1a.id

  tags = {
    Name = "portfolio-nat-gw"
  }
}

# ==========================================
# Private Route Table (EC2 subnets)
# アウトバウンド: NAT Gateway 経由
# ==========================================
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "portfolio-private-rt"
  }
}

resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private.id
}

# ==========================================
# DB Route Table (RDS subnets)
# インターネット経路なし — VPC 内ローカル通信のみ
# ==========================================
resource "aws_route_table" "db" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "portfolio-db-rt"
  }
}
