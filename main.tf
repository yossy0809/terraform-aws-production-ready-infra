# 1. AWSプロバイダーの設定
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # 2026年現在の安定版バージョンを指定
    }
  }
}

provider "aws" {
  region = "ap-northeast-1" # 東京リージョン
}

# 2. VPCの作成
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "portfolio-vpc"
  }
}

# 3. インターネットゲートウェイの作成（Web層が外と通信するために必要）
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "portfolio-igw"
  }
}
# ==========================================
# 4. パブリックサブネットの作成（マルチAZ構成）
# ==========================================
resource "aws_subnet" "public_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"

  # このサブネット内で起動したインスタンスに自動でパブリックIPを割り当てる設定
  map_public_ip_on_launch = true

  tags = {
    Name = "portfolio-public-subnet-1a"
  }
}

resource "aws_subnet" "public_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-1c"
  
  map_public_ip_on_launch = true

  tags = {
    Name = "portfolio-public-subnet-1c"
  }
}

# ==========================================
# 5. パブリック用ルートテーブルの作成
# ==========================================
# 「インターネット（0.0.0.0/0）への通信は、さっき作ったIGWを通ってね」というルールを定義
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "portfolio-public-rt"
  }
}

# ==========================================
# 6. ルートテーブルをパブリックサブネットに紐付け
# ==========================================
resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1c" {
  subnet_id      = aws_subnet.public_1c.id
  route_table_id = aws_route_table.public.id
}
# ==========================================
# 7. プライベートサブネットの作成（Web/Appサーバー用）
# ==========================================
resource "aws_subnet" "private_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "portfolio-private-subnet-1a"
  }
}

resource "aws_subnet" "private_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "portfolio-private-subnet-1c"
  }
}

# ==========================================
# 8. データサブネットの作成（RDS用）
# ==========================================
resource "aws_subnet" "db_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "portfolio-db-subnet-1a"
  }
}

resource "aws_subnet" "db_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.22.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "portfolio-db-subnet-1c"
  }
}

# ==========================================
# 外部（インターネット）と直接通信しないため、ルートの定義（routeブロック）は空のままでOK
# ==========================================
# 10. ルートテーブルの紐付け
# ※ private_1a の紐付けは nat_gateway.tf に記載
# ==========================================

resource "aws_route_table_association" "private_1c" {
  subnet_id      = aws_subnet.private_1c.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "db_1a" {
  subnet_id      = aws_subnet.db_1a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "db_1c" {
  subnet_id      = aws_subnet.db_1c.id
 route_table_id = aws_route_table.private.id
}