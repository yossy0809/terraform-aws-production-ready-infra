# ==========================================
# ALB Security Group
# ==========================================
resource "aws_security_group" "alb" {
  name        = "portfolio-alb-sg"
  description = "Allow HTTP traffic from internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "portfolio-alb-sg"
  }
}

# ==========================================
# EC2 Security Group — ALB からのトラフィックのみ許可
# ==========================================
resource "aws_security_group" "ec2" {
  name        = "portfolio-ec2-sg"
  description = "Allow traffic only from ALB"
  vpc_id      = aws_vpc.main.id

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
# RDS Security Group — EC2 からのトラフィックのみ許可
# ==========================================
resource "aws_security_group" "rds" {
  name        = "portfolio-rds-sg"
  description = "Allow MySQL traffic only from EC2"
  vpc_id      = aws_vpc.main.id

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
