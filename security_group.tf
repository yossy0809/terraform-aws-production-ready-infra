# ==========================================
# 1. ALB（ロードバランサー）用のセキュリティグループ
# ==========================================
resource "aws_security_group" "alb" {
  name        = "portfolio-alb-sg"
  description = "Allow HTTP traffic from internet"
  vpc_id      = aws_vpc.main.id

  # 【インバウンド】インターネット全体からのHTTP(80ポート)接続を許可
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 【アウトバウンド】すべての宛先への通信を許可
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "portfolio-alb-sg"
  }
}

# ==========================================
# 2. EC2（Web/Appサーバー）用のセキュリティグループ
# ==========================================
resource "aws_security_group" "ec2" {
  name        = "portfolio-ec2-sg"
  description = "Allow traffic only from ALB"
  vpc_id      = aws_vpc.main.id

  # 【インバウンド】上で定義した「ALB用SG」からのHTTP接続のみを許可！
  ingress {
    from_port       = 80
    to_port         = 80
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
    Name = "portfolio-ec2-sg"
  }
}

# ==========================================
# 3. RDS（データベース）用のセキュリティグループ
# ==========================================
resource "aws_security_group" "rds" {
  name        = "portfolio-rds-sg"
  description = "Allow traffic only from EC2"
  vpc_id      = aws_vpc.main.id

  # 【インバウンド】「EC2用SG」からのMySQL接続(3306ポート)のみを許可！
  # ※PostgreSQLを使用する場合は portを 5432 に変更してください。ここでは一旦MySQL(3306)で進めます。
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "portfolio-rds-sg"
  }
}