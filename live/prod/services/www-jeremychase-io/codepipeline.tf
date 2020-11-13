# BUG(medium) check cloudwatch log retension after destroy

# BUG(medium) maybe move to variable
locals {
  project_name = "www-jeremychase-io"
}

resource "aws_s3_bucket" "www_jeremychase_io" {
  bucket        = "www.jeremychase.io"
  acl           = "private"
  force_destroy = var.force_destroy_s3_buckets

  tags = {
    Project = "www.jeremychase.io"
  }

  lifecycle_rule {
    id      = "Intelligent-Tiering"
    enabled = true

    transition {
      days          = 1 # BUG(medium) check
      storage_class = "INTELLIGENT_TIERING"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "www_jeremychase_io" {
  bucket = aws_s3_bucket.www_jeremychase_io.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "www_jeremychase_io_codepipeline_bucket" {
  bucket        = "codepipeline-www.jeremychase.io"
  acl           = "private"
  force_destroy = var.force_destroy_s3_buckets

  lifecycle_rule {
    id      = "Remove CodePipeline artifacts"
    enabled = true

    # Remove objects
    expiration {
      days = 7 # BUG(medium) verify
    }
  }
}

resource "aws_s3_bucket_public_access_block" "www_jeremychase_io_codepipeline_bucket" {
  bucket = aws_s3_bucket.www_jeremychase_io_codepipeline_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "oai" {
  bucket = aws_s3_bucket.www_jeremychase_io.id

  policy = data.aws_iam_policy_document.aws_s3_bucket_policy_oai.json
}

# BUG(low) rethink terraform resource name.
data "aws_iam_policy_document" "aws_s3_bucket_policy_oai" {
  policy_id = "PolicyForCloudFrontPrivateContent"

  statement {
    actions   = ["s3:GetObject", ]
    resources = ["arn:aws:s3:::${aws_s3_bucket.www_jeremychase_io.id}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
  }
}

resource "aws_iam_role" "codebuild" {
  name = "${local.project_name}-codebuild" # BUG(low) rethink name

  assume_role_policy = data.aws_iam_policy_document.codebuild_trust_relationship.json
}

# BUG(low) rethink terraform resource name.
data "aws_iam_policy_document" "codebuild_trust_relationship" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

# BUG(low) rethink terraform resource name.
resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/aws/codebuild/${local.project_name}"
  retention_in_days = 365
}

# BUG(low) rethink terraform resource name.
data "aws_iam_policy_document" "codebuild_logging" {
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.codebuild.arn}:*"]
  }
}

# BUG(low) rethink terraform resource name.
resource "aws_iam_policy" "codebuild_logging" {
  name        = "${local.project_name}-codebuild-cloudwatch-allow" # BUG(low) rethink name
  path        = "/"
  description = "Allow ${local.project_name} CodeBuild to use CloudWatch"

  policy = data.aws_iam_policy_document.codebuild_logging.json
}

# BUG(low) rethink terraform resource name.
resource "aws_iam_role_policy_attachment" "codebuild_cloudwatch" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.codebuild_logging.arn
}

# BUG(low) rethink terraform resource name.
# BUG(medium) Some of these actions may not be necessary.
data "aws_iam_policy_document" "kms_allow" {
  statement {
    actions = [
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:Decrypt"
    ]
    resources = [aws_kms_key.codepipeline_artifact_store.arn]
  }
}

# BUG(low) rethink terraform resource name.
resource "aws_iam_policy" "kms_allow" {
  name        = "${local.project_name}-kms-allow" # BUG(low) rethink name
  path        = "/"
  description = "Allow ${local.project_name} access to KMS for CodePipeline artifact storage in S3"

  policy = data.aws_iam_policy_document.kms_allow.json
}

# BUG(low) rethink terraform resource name.
resource "aws_iam_role_policy_attachment" "codebuild_kms_allow" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.kms_allow.arn
}

# BUG(medium) rename terraform resource.
resource "aws_iam_role_policy_attachment" "s3_bucket_policy_attach" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.codepipeline_bucket_allow.arn
}

# BUG(medium) rename terraform resource.
resource "aws_codebuild_project" "www_jeremychase_io" {
  name           = local.project_name
  description    = "Build ${local.project_name}"
  build_timeout  = "5"
  queued_timeout = "5"

  service_role = aws_iam_role.codebuild.arn

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild.name
      stream_name = "build/${local.project_name}"
    }
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.www_jeremychase_io_codepipeline_bucket.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:1.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type = "CODEPIPELINE"

    # BUG(medium) move to ReactJS repository
    # BUG(medium) possibly replace with https://github.com/terraform-providers/terraform-provider-aws/issues/5101#issuecomment-496663099
    buildspec = <<BUILDSPEC
version: 0.2

phases:
  pre_build:
    commands:
      - yarn install
  build:
    commands:
      - yarn build
artifacts:
  files:
    - '**/*'
  base-directory: build
BUILDSPEC
  }

  tags = {
    Project = "www.jeremychase.io"
  }
}

resource "aws_codepipeline" "www_jeremychase_io" {
  name     = "www-jeremychase-io-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.www_jeremychase_io_codepipeline_bucket.bucket
    type     = "S3"

    encryption_key {
      id   = aws_kms_key.codepipeline_artifact_store.arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      # BUG(medium) look for issue where cycling token causes CodePipeline to lose access to GitHub
      configuration = {
        Owner      = "JeremyChase"
        Repo       = "www.jeremychase.io"
        Branch     = "master"
        OAuthToken = var.github_personal_access_token
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = "www-jeremychase-io"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        BucketName = aws_s3_bucket.www_jeremychase_io.id
        Extract    = "true"
      }
    }
  }

  stage {
    name = "InvalidateCloudFrontCache"

    action {
      name     = "InvokeInvalidationLambda"
      category = "Invoke"
      owner    = "AWS"
      provider = "Lambda"
      version  = "1" # https://docs.aws.amazon.com/codepipeline/latest/userguide/reference-pipeline-structure.html says "1" is the only valid type.

      configuration = {
        FunctionName   = aws_lambda_function.cloudfront_invalidate.function_name
        UserParameters = aws_cloudfront_distribution.s3.id # UserParameters is a string and could be JSON. Since we are passing a single argument that is unnecessary.
      }
    }
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-role"

  assume_role_policy = data.aws_iam_policy_document.codepipeline_trust_relationship.json
}

# BUG(low) rethink terraform resource name.
data "aws_iam_policy_document" "codepipeline_trust_relationship" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

# BUG(low) rethink terraform resource name.
data "aws_iam_policy_document" "codepipeline_bucket_allow" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.www_jeremychase_io_codepipeline_bucket.arn}",
      "${aws_s3_bucket.www_jeremychase_io_codepipeline_bucket.arn}/*" // BUG(medium) Necessary?
    ]
  }
}

# BUG(low) rethink terraform resource name.
# used by aws_iam_role.codebuild, which is the service_role for aws_codebuild_project
resource "aws_iam_policy" "codepipeline_bucket_allow" {
  name        = "${local.project_name}-codepipeline-bucket-allow"
  description = "Allow ${local.project_name} access to bucket used by CodePipeline"

  policy = data.aws_iam_policy_document.codepipeline_bucket_allow.json
}

# BUG(low) rethink terraform resource name.
resource "aws_iam_role_policy_attachment" "codepipeline_codepipeline_bucket_allow" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_bucket_allow.arn
}

# BUG(low) rethink terraform resource name.
resource "aws_iam_role_policy_attachment" "codepipeline_kms_allow" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.kms_allow.arn
}

# BUG(low) rethink terraform resource name.
data "aws_iam_policy_document" "codepipeline_s3_origin_allow" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectVersionAcl",
      "s3:PutObject"
    ]
    resources = [
      aws_s3_bucket.www_jeremychase_io.arn,
      "${aws_s3_bucket.www_jeremychase_io.arn}/*"
    ]
  }
}

# BUG(high) switch to aws_iam_policy and aws_iam_role_policy_attachment
# BUG(low) rethink terraform resource name.
resource "aws_iam_role_policy" "codepipeline_s3_origin_allow" {
  name = "s3_origin_allow"

  role = aws_iam_role.codepipeline_role.id

  policy = data.aws_iam_policy_document.codepipeline_s3_origin_allow.json
}

# BUG(low) rethink terraform resource name.
data "aws_iam_policy_document" "codepipeline_codebuild_allow" {
  statement {
    actions   = ["codebuild:BatchGetBuilds", "codebuild:StartBuild"]
    resources = [aws_codebuild_project.www_jeremychase_io.arn]
  }
}

# BUG(high) switch to aws_iam_policy and aws_iam_role_policy_attachment
# BUG(low) rethink terraform resource name.
resource "aws_iam_role_policy" "codepipeline_codebuild_allow" {
  name = "codebuild_allow"

  role = aws_iam_role.codepipeline_role.id

  policy = data.aws_iam_policy_document.codepipeline_codebuild_allow.json
}

# BUG(medium) evaluate pricing
resource "aws_kms_key" "codepipeline_artifact_store" {
  description = "Used for ${local.project_name} CodePipeline artifact storage in S3"
}

# The alias is not required but does neaten up the console output.
resource "aws_kms_alias" "codepipeline_artifact_store" {
  name          = "alias/codepipeline_artifact_store"
  target_key_id = aws_kms_key.codepipeline_artifact_store.key_id
}
