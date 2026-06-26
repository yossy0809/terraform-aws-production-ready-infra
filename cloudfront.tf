# ==========================================
# CloudFront Distribution
# ALB をオリジンとするCDN
# 静的コンテンツのエッジキャッシュ + ALBへの直接アクセスをブロック
# ==========================================

# CloudFront エッジノードの IP レンジ（ALB SG で参照）
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_lb.alb.dns_name
    origin_id   = "alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "alb-origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    # HTTP アクセスは HTTPS へリダイレクト
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # デフォルト証明書（*.cloudfront.net ドメイン用）
  # 本番では ACM でカスタムドメイン証明書を発行して差し替える
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "portfolio-cloudfront"
  }
}
