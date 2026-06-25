# ==========================================
# 1. ALB（ロードバランサー本体）の作成
# ==========================================
resource "aws_lb" "alb" {
  name               = "portfolio-alb"
  internal           = false # インターネット向け
  load_balancer_type = "application"
  
  # 紐付けるセキュリティグループ（ALB用SG）
  security_groups    = [aws_security_group.alb.id]
  
  # ALBを配置するサブネット（パブリックサブネット2つを指定）
  subnets            = [aws_subnet.public_1a.id, aws_subnet.public_1c.id]

  tags = {
    Name = "portfolio-alb"
  }
}

# ==========================================
# 2. ターゲットグループの作成（通信の転送先グループ）
# ==========================================
resource "aws_lb_target_group" "tg" {
  name     = "portfolio-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  # ヘルスチェック（EC2が元気に動いているか確認する設定）
  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 15
    matcher             = "200"
  }

  tags = {
    Name = "portfolio-tg"
  }
}

# ==========================================
# 3. ALBのリスナー設定（入り口のルール）
# ==========================================
# 「HTTP（80番ポート）でアクセスが来たら、上のターゲットグループに流す」という設定
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# ==========================================
# 4. ターゲットグループにEC2を登録
# ==========================================
resource "aws_lb_target_group_attachment" "web_app" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web_app.id # さっき作ったEC2を指定
  port             = 80
}