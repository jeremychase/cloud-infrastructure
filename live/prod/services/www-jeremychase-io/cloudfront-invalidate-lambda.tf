
# BUG(low) rethink terraform resource name.
# BUG(medium) pull out this role policy
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
data "aws_iam_policy_document" "invalidation_lambda_codepipeline_allow" {
  statement {
    actions   = ["codepipeline:PutJobSuccessResult", "codepipeline:PutJobFailureResult"]

    #
    # As of September 2020, CodePipeline has partial Resource-level permission support. The
    # documentation for PutJobSuccessResult and PutJobFailureResult both read:
    # "Supports only a wildcard (*) in the policy Resource element."
    #
    # See:
    #  https://docs.aws.amazon.com/codepipeline/latest/userguide/permissions-reference.html
    #  https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_policies.html#mismatch_action-no-resource
    #  https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_aws-services-that-work-with-iam.html#deploy_svcs
    #
    resources = ["*"]
  }
}

# BUG(low) rethink terraform resource name.
resource "aws_iam_policy" "invalidation_lambda_codepipeline_allow" {
  name        = "${local.project_name}-invalidation-lambda-codepipeline-allow" # BUG(medium) rethink name
  path        = "/"
  description = "Allow ${local.project_name} CloudFront-Invalitation Lambda to report result to CodePipeline"

  policy = data.aws_iam_policy_document.invalidation_lambda_codepipeline_allow.json
}

# BUG(low) rethink terraform resource name.
resource "aws_iam_role_policy_attachment" "invalidation_lambda_codepipeline_allow" {
  role       = aws_iam_role.cloudfront_invalidation_lambda.name
  policy_arn = aws_iam_policy.invalidation_lambda_codepipeline_allow.arn
}

# BUG(low) rethink terraform resource name.
data "aws_iam_policy_document" "lambda_cloudfront_invalidate" {
  statement {
    actions   = ["cloudfront:CreateInvalidation"]
    resources = ["*"] # BUG(high,wip) target cf distribution
  }
}

# BUG(low) rethink terraform resource name.
resource "aws_iam_policy" "lambda_cloudfront_invalidate" {
  name        = "lambda_cloudfront_invalidate" # BUG(medium) rethink name
  path        = "/"
  description = "Allow Lambda to invalidate CloudFront"

  policy = data.aws_iam_policy_document.lambda_cloudfront_invalidate.json
}

# BUG(low) rethink terraform resource name.
resource "aws_iam_role_policy_attachment" "lambda_cloudfront_invalidate" {
  role       = aws_iam_role.cloudfront_invalidation_lambda.name
  policy_arn = aws_iam_policy.lambda_cloudfront_invalidate.arn
}

locals {
  cloudfront_invalidate_lambda_file_name = "cloudfront_invalidate"
}

data "archive_file" "cloudfront_invalidate_lambda" {
  type        = "zip"
  source_file = "${path.module}/files/${local.cloudfront_invalidate_lambda_file_name}.py"
  output_path = "${path.module}/build/${local.cloudfront_invalidate_lambda_file_name}.zip"
}

# BUG(low) rethink terraform resource name.
resource "aws_lambda_function" "cloudfront_invalidate" {
  filename      = data.archive_file.cloudfront_invalidate_lambda.output_path
  function_name = local.cloudfront_invalidate_lambda_file_name    # BUG(medium) rename to include project name
  role          = aws_iam_role.cloudfront_invalidation_lambda.arn # BUG(medium) check this
  handler       = "${local.cloudfront_invalidate_lambda_file_name}.lambda_handler"

  publish = false # Not required

  source_code_hash = filebase64sha256(data.archive_file.cloudfront_invalidate_lambda.output_path)

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
