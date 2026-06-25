# ==========================================
# 1. NATゲートウェイ用の固定IP（Elastic IP）
# ==========================================
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "portfolio-nat-eip"
  }
}

# ==========================================
# 2. NATゲートウェイの作成（パブリックに配置）
# ==========================================
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1a.id # パブリックに置くのが鉄則！

  tags = {
    Name = "portfolio-nat-gw"
  }
}

# ==========================================
# 3. プライベートサブネット用のルートテーブル
# ==========================================
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  # 外への通信（0.0.0.0/0）はすべてNATゲートウェイに送る設定
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "portfolio-private-rt"
  }
}

# ==========================================
# 4. ルートテーブルをプライベートサブネットに紐付け
# ==========================================
resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private.id
}