output "alb_dns_name" {
  description = "ALB のパブリック DNS 名"
  value       = aws_lb.alb.dns_name
}

output "rds_endpoint" {
  description = "RDS エンドポイント"
  value       = aws_db_instance.mysql.endpoint
  sensitive   = true
}
