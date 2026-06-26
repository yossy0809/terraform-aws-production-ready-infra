resource "aws_db_subnet_group" "rds" {
  name       = "portfolio-rds-subnet-group"
  subnet_ids = [aws_subnet.db_1a.id, aws_subnet.db_1c.id]

  tags = {
    Name = "portfolio-rds-subnet-group"
  }
}

resource "aws_db_instance" "mysql" {
  allocated_storage     = 20
  max_allocated_storage = 50
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t3.micro"

  db_name  = "portfolio_db"
  username = "admin"
  password = aws_ssm_parameter.db_password.value

  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az                = true # AZ 障害時の自動フェイルオーバー
  storage_encrypted       = true # 保存データの暗号化
  backup_retention_period = 7    # 自動バックアップを 7 日間保持

  skip_final_snapshot = true # 検証環境のため無効化

  tags = {
    Name = "portfolio-rds-mysql"
  }
}
