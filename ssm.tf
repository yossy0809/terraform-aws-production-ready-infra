# ==========================================
# DBパスワードをParameter Storeに安全に保管
# ==========================================
resource "aws_ssm_parameter" "db_password" {
  name        = "/portfolio/database/password"
  description = "Database master password"
  type        = "SecureString" # これでAWS側で自動的に暗号化されます
  value       = var.db_password

  tags = {
    Name = "portfolio-db-password"
  }
}

# ==========================================
# SSM Session Manager 用 IAM設定
# ==========================================

# EC2に付与するIAMロール
resource "aws_iam_role" "ec2_ssm" {
  name = "portfolio-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = {
    Name = "portfolio-ec2-ssm-role"
  }
}

# SSM Session Manager に必要なポリシーを付与
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EC2にIAMロールを紐付けるためのインスタンスプロファイル
resource "aws_iam_instance_profile" "ec2_ssm" {
  name = "portfolio-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm.name
}