resource "aws_s3_bucket" "www_jeremychase_io_logs" {
  bucket = "logs-www.jeremychase.io" # BUG(medium) change name
  acl    = "private"

  tags = {
    Project = "www.jeremychase.io" #BUG(low) fix tags
  }

  lifecycle_rule {
    id      = "Intelligent-Tiering"
    enabled = true

    transition {
      days          = 0 # BUG(medium) check
      storage_class = "INTELLIGENT_TIERING"
    }
  }

  lifecycle_rule {
    id      = "Remove old logs"
    enabled = true

    expiration {
      days = 365 # BUG(medium) check
    }
  }
}

resource "aws_s3_bucket_public_access_block" "www_jeremychase_io_logs" {
  bucket = aws_s3_bucket.www_jeremychase_io_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

locals {
  s3_origin_id = aws_s3_bucket.www_jeremychase_io.bucket_regional_domain_name
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "www.jeremychase.io"
}

# BUG(high) redirect from www to apex, might need lambda_function_association
resource "aws_cloudfront_distribution" "s3" {
  aliases = ["jeremychase.io", "www.jeremychase.io"]

  enabled         = true
  is_ipv6_enabled = true

  default_root_object = "index.html"

  # Handle non-root level requests
  custom_error_response {
    error_code         = 403 # S3 returns Access Denied when object is missing
    response_code      = 200
    response_page_path = "/index.html"
  }

  origin {
    domain_name = aws_s3_bucket.www_jeremychase_io.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.www_jeremychase_io_logs.bucket_domain_name
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    default_ttl            = 300 # BUG(low) increase
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Project = "www.jeremychase.io"
  }

  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate_validation.jeremychase_io.certificate_arn
    cloudfront_default_certificate = false
    ssl_support_method             = "sni-only"
  }
}
