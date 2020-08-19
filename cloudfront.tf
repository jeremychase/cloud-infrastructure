locals {
  s3_origin_id = "S3Bucket" # BUG(medium) maybe change name
}

# BUG convert TODO into BUG comments

# BUG(high) set storage class
# BUG(high) enable lifecycle
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
      days          = 0 # BUG(high) check
      storage_class = "INTELLIGENT_TIERING"
    }
  }

  lifecycle_rule {
    id      = "Remove old logs"
    enabled = true

    expiration {
      days = 365 # BUG(high) check
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

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "www.jeremychase.io"
}

# TODO redirect from www to apex
# BUG(high) go through every line
resource "aws_cloudfront_distribution" "s3_distribution" { # TODO(high) rename
  origin {
    domain_name = aws_s3_bucket.www_jeremychase_io.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment" # TODO(high) update
  default_root_object = "index.html"

  logging_config { # TODO(high) fix
    include_cookies = false
    bucket          = aws_s3_bucket.www_jeremychase_io_logs.bucket_domain_name
    prefix          = "myprefix" # TODO(high) update
  }

  aliases = ["jeremychase.io", "www.jeremychase.io"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600  # TODO(high) increase
    max_ttl                = 86400 # TODO(high) increase
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
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
