data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_launch_template" "web_app" {
  name_prefix   = "portfolio-web-app-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.ec2.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_ssm.name
  }

  # Nginx のインストールと起動
  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nginx
              systemctl start nginx
              systemctl enable nginx
              echo "<h1>Hello from 3-Tier Architecture Web Server!</h1>" > /usr/share/nginx/html/index.html
              EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "portfolio-web-app-server"
    }
  }
}

resource "aws_autoscaling_group" "web_app" {
  name                = "portfolio-web-app-asg"
  vpc_zone_identifier = [aws_subnet.private_1a.id, aws_subnet.private_1c.id]

  min_size         = 1
  max_size         = 2
  desired_capacity = 1

  launch_template {
    id      = aws_launch_template.web_app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "portfolio-web-app-server"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_attachment" "web_app" {
  autoscaling_group_name = aws_autoscaling_group.web_app.name
  lb_target_group_arn    = aws_lb_target_group.tg.arn
}
