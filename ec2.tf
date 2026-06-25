# ==========================================
# 1. 最新の Amazon Linux 2023 の AMI ID を自動取得
# ==========================================
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# ==========================================
# 2. EC2インスタンスの作成
# ==========================================
resource "aws_instance" "web_app" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro" # 無料枠対象（アカウントや時期によってt2.microの場合もあります）

  # 配置するサブネット（プライベートサブネット1aを指定）
  subnet_id     = aws_subnet.private_1a.id
  
  # 紐付けるセキュリティグループ（前回作ったEC2用SGを指定）
  vpc_security_group_ids = [aws_security_group.ec2.id]

  # 【ユーザーデータ】サーバー起動時に実行する初期化スクリプト
  # Nginxをインストールして、簡単なテストページを作成・起動します
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nginx
              systemctl start nginx
              systemctl enable nginx
              echo "<h1>Hello from 3-Tier Architecture Web Server!</h1>" > /usr/share/nginx/html/index.html
              EOF

  # SSM Session Manager でログインするためのIAMプロファイルを紐付け
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm.name

  tags = {
    Name = "portfolio-web-app-server"
  }
}