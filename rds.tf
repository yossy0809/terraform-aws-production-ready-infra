# ==========================================
# 1. RDS用のサブネットグループの作成
# ==========================================
# RDSをマルチAZ（2つの異なる場所）に配置するために、事前に作った2つのDBサブネットを1つにまとめます
resource "aws_db_subnet_group" "rds" {
  name       = "portfolio-rds-subnet-group"
  subnet_ids = [aws_subnet.db_1a.id, aws_subnet.db_1c.id]

  tags = {
    Name = "portfolio-rds-subnet-group"
  }
}

# ==========================================
# 2. RDS（MySQL）インスタンスの作成
# ==========================================
resource "aws_db_instance" "mysql" {
  allocated_storage    = 20            # ストレージ容量（20GBは無料枠内）
  max_allocated_storage = 50           # 自動拡張の上限
  engine               = "mysql"
  engine_version       = "8.0"       # MySQLのバージョン
  instance_class       = "db.t3.micro"  # 無料枠対象のインスタンスタイプ

  db_name              = "portfolio_db" # 初期データベース名
  username             = "admin"        # マスターユーザー名
password             = aws_ssm_parameter.db_password.value
  # 配置設定
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id] # RDS用のSGを紐付け
  skip_final_snapshot    = true          # 削除時にバックアップを作成しない設定（検証用）
  multi_az               = true          # マルチAZ構成（フェイルオーバー対応）

  tags = {
    Name = "portfolio-rds-mysql"
  }
}