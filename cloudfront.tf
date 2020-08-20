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

  # BUG(high) segment cache based on request Host header

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
    default_ttl            = 60 # BUG(low) increase

    # Use Lambda@Edge for subdomain redirect
    lambda_function_association {
      event_type = "origin-request" # Generate cacheable response before hitting origin: https://aws.amazon.com/blogs/networking-and-content-delivery/lambdaedge-design-best-practices/

      # lambda_arn = "${aws_lambda_function.subdomain_redirect.arn}:1" # BUG(high) https://github.com/terraform-providers/terraform-provider-aws/issues/8081
      lambda_arn = aws_lambda_function.subdomain_redirect.qualified_arn # BUG(low) should be default
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
  name = "iam_for_lambda" # BUG(low) This should be renamed


  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
         "Principal": {
            "Service": [
               "lambda.amazonaws.com",
               "edgelambda.amazonaws.com"
            ]
         },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# BUG(high) fix comment and/or policy
# This is to optionally manage the CloudWatch Log Group for the Lambda Function.
# If skipping this resource configuration, also add "logs:CreateLogGroup" to the IAM policy below.
resource "aws_cloudwatch_log_group" "example" {
  name              = "/aws/lambda/${aws_lambda_function.subdomain_redirect.function_name}"
  retention_in_days = 14
}

# BUG(high) why are there two log groups?

# BUG(medium) resolve and remove logs:CreateLogGroup
resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

# BUG(high) fix zip creation issue
resource "aws_lambda_function" "subdomain_redirect" {
  filename      = "subdomain_redirect.zip"        # BUG(medium) move
  function_name = "subdomain_redirect"            # BUG(medium) include domain in function_name
  role          = aws_iam_role.iam_for_lambda.arn # BUG(medium) change this
  handler       = "subdomain_redirect.lambda_handler"

  publish = true

  source_code_hash = filebase64sha256("subdomain_redirect.zip")

  runtime = "python3.8"
}

# This gives CloudFront access Lambda function
resource "aws_lambda_permission" "allow_cloudfront" {
  statement_id  = "AllowExecutionFromCloudFront" # BUG(medium) check name
  action        = "lambda:GetFunction"
  function_name = aws_lambda_function.subdomain_redirect.function_name
  principal     = "replicator.lambda.amazonaws.com"
  # source_arn    = "${aws_lambda_function.subdomain_redirect.arn}:1" # BUG(high) DRY
  source_arn = aws_lambda_function.subdomain_redirect.qualified_arn # BUG(low) should be default
}
