output "cloudfront_domain_name" {
  description = "CloudFront ドメイン名（アクセス URL）"
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "alb_dns_name" {
  description = "ALB DNS 名（CloudFront 経由でのみ公開 — 直接アクセス不可）"
  value       = aws_lb.alb.dns_name
}

output "rds_endpoint" {
  description = "RDS エンドポイント"
  value       = aws_db_instance.mysql.endpoint
  sensitive   = true
}
