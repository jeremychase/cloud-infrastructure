
# BUG(low) rethink terraform resource name.
# BUG(high) pull out this role policy
resource "aws_iam_role" "cloudfront_invalidation_lambda" {
  name = "cloudfront_invalidation_lambda" # BUG(low) This should be renamed

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
         "Principal": {
            "Service": [
               "lambda.amazonaws.com"
            ]
         },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# BUG(low) rethink terraform resource name.
resource "aws_cloudwatch_log_group" "cloudfront_invalidate" {
  name              = "/aws/lambda/${aws_lambda_function.cloudfront_invalidate.function_name}"
  retention_in_days = 365
}

# BUG(low) rethink terraform resource name.
data "aws_iam_policy_document" "cloudfront_invalidate_lambda_logging" {
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.cloudfront_invalidate.arn}:*"]
  }
}

resource "aws_iam_policy" "cloudfront_invalidate_lambda_logging" {
  name        = "cloudfront_invalidate_lambda_logging" # BUG(medium) rename
  path        = "/"
  description = "Allow CloudFront Invalitation Lambda to log"

  policy = data.aws_iam_policy_document.cloudfront_invalidate_lambda_logging.json
}

# BUG(low) rethink terraform resource name.
resource "aws_iam_role_policy_attachment" "cloudfront_invalidation_lambda_logs" {
  role       = aws_iam_role.cloudfront_invalidation_lambda.name
  policy_arn = aws_iam_policy.cloudfront_invalidate_lambda_logging.arn
}


# BUG(low) rethink terraform resource name.
data "aws_iam_policy_document" "cloudfront_invalidate_codepipeline_result" {
  statement {
    actions   = ["codepipeline:PutJobSuccessResult", "codepipeline:PutJobFailureResult"]
    resources = ["*"] # BUG(high) target pipeline
  }
}

# BUG(high) fix logging target
resource "aws_iam_policy" "cloudfront_invalidate_codepipeline_result" {
  name        = "cloudfront_invalidate_codepipeline_result" # BUG(medium) rethink name
  path        = "/"
  description = "Allow CloudFront Invalitation Lambda to log"

  policy = data.aws_iam_policy_document.cloudfront_invalidate_codepipeline_result.json
}

# BUG(low) rethink name
resource "aws_iam_role_policy_attachment" "cloudfront_invalidation_lambda_codepipeline_result" {
  role       = aws_iam_role.cloudfront_invalidation_lambda.name
  policy_arn = aws_iam_policy.cloudfront_invalidate_codepipeline_result.arn
}

# BUG(low) rethink terraform resource name.
data "aws_iam_policy_document" "lambda_cloudfront_invalidate" {
  statement {
    actions   = ["cloudfront:CreateInvalidation"]
    resources = ["*"] # BUG(high) target cf distribution
  }
}

# BUG(high) fix logging target
resource "aws_iam_policy" "lambda_cloudfront_invalidate" {
  name        = "lambda_cloudfront_invalidate" # BUG(medium) rethink name
  path        = "/"
  description = "Allow Lambda to invalidate CloudFront"

  policy = data.aws_iam_policy_document.lambda_cloudfront_invalidate.json
}

# BUG(low) rethink name
resource "aws_iam_role_policy_attachment" "lambda_cloudfront_invalidate" {
  role       = aws_iam_role.cloudfront_invalidation_lambda.name
  policy_arn = aws_iam_policy.lambda_cloudfront_invalidate.arn
}


# BUG(high) fix zip creation issue
# BUG(low) rethink terraform resource name.
resource "aws_lambda_function" "cloudfront_invalidate" {
  filename      = "cloudfront_invalidate.zip"                     # BUG(medium) move
  function_name = "cloudfront_invalidate"                         # BUG(medium) rename to include project name
  role          = aws_iam_role.cloudfront_invalidation_lambda.arn # BUG(medium) check this
  handler       = "cloudfront_invalidate.lambda_handler"

  publish = false #BUG(medium) may need?

  source_code_hash = filebase64sha256("cloudfront_invalidate.zip")

  runtime = "python3.8"
}

# BUG(medium) rename terraform resource
data "aws_iam_policy_document" "codepipeline_invoke_lambda" {
  statement {
    actions = ["lambda:InvokeFunction"]
    # resources = ["${aws_lambda_function.cloudfront_invalidation_lambda.arn}"] // BUG(high) fix
    resources = ["*"]
  }
}

resource "aws_iam_policy" "codepipeline_invoke_lambda" {
  name        = "codepipeline_invoke_lambda" # BUG(medium) rename
  path        = "/"
  description = "Allow CodePipeline to invoke Invaldiation lambda"

  policy = data.aws_iam_policy_document.codepipeline_invoke_lambda.json
}

resource "aws_iam_role_policy_attachment" "codepipeline_invoke_lambda" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_invoke_lambda.arn
}
