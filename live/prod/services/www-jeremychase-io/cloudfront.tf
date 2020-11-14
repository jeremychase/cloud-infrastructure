resource "aws_s3_bucket" "www_jeremychase_io_logs" {
  bucket        = "logs-www.jeremychase.io" # BUG(medium) change name
  acl           = "private"
  force_destroy = var.force_destroy_s3_buckets

  #BUG(low) fix tags

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
      headers      = ["Host"] # Segment cache between subdomain and apex. S3 Origin requires Host header to be reconstructed via Lambda@Edge

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    default_ttl            = 86400 # One day (24 * 60 * 60)

    # Use Lambda@Edge for subdomain redirect
    lambda_function_association {
      event_type = "origin-request" # Generate cacheable response before hitting origin: https://aws.amazon.com/blogs/networking-and-content-delivery/lambdaedge-design-best-practices/
      lambda_arn = aws_lambda_function.subdomain_redirect.qualified_arn
    }
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

# BUG(medium) This should be replaced
# BUG(medium) This might not need edgelambda.amazonaws.com
# BUG(low) This should be renamed
resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda" # BUG(high) rename
  assume_role_policy = data.aws_iam_policy_document.iam_for_lambda.json
}

# BUG(low) rethink terraform resource name.
data "aws_iam_policy_document" "iam_for_lambda" {
  statement {
    sid = ""

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
    }
  }
}

# BUG(medium) rename terraform resource
resource "aws_cloudwatch_log_group" "subdomain_redirect" {
  name              = "/aws/lambda/${data.aws_region.current.name}.${aws_lambda_function.subdomain_redirect.function_name}"
  retention_in_days = 365
}

# BUG(medium) rename terraform resource
data "aws_iam_policy_document" "lambda_logging" {
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.subdomain_redirect.arn}:*"]
  }
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging" # BUG(medium) rename
  path        = "/"
  description = "Allow Lambda@Edge to log"

  policy = data.aws_iam_policy_document.lambda_logging.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

locals {
  subdomain_redirect_lambda_file_name = "subdomain_redirect"
}

data "archive_file" "subdomain_redirect_lambda" {
  type        = "zip"
  source_file = "${path.module}/files/${local.subdomain_redirect_lambda_file_name}.py"
  output_path = "${path.module}/build/${local.subdomain_redirect_lambda_file_name}.zip"
}

# BUG(medium) rename terraform resource. include Lambda@Edge trigger
resource "aws_lambda_function" "subdomain_redirect" {
  filename      = data.archive_file.subdomain_redirect_lambda.output_path
  function_name = local.subdomain_redirect_lambda_file_name # BUG(medium) include domain and Lambda@Edge trigger
  role          = aws_iam_role.iam_for_lambda.arn           # BUG(medium) check this
  handler       = "${local.subdomain_redirect_lambda_file_name}.lambda_handler"

  publish = true # Required for use with CloudFront Lambda@Edge

  source_code_hash = filebase64sha256(data.archive_file.subdomain_redirect_lambda.output_path)

  runtime = "python3.8"
}

# This gives CloudFront access Lambda function
resource "aws_lambda_permission" "allow_cloudfront" {
  statement_id  = "AllowExecutionFromCloudFront" # BUG(medium) check name
  action        = "lambda:GetFunction"
  function_name = aws_lambda_function.subdomain_redirect.function_name
  principal     = "replicator.lambda.amazonaws.com"
  source_arn    = aws_lambda_function.subdomain_redirect.qualified_arn
}
