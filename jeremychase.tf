
resource "aws_s3_bucket" "www_jeremychase_io" {
  bucket = "www.jeremychase.io"
  acl    = "private"

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
  bucket = "codepipeline-www.jeremychase.io"
  acl    = "private"

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

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "PolicyForCloudFrontPrivateContent",
  "Statement": [
      {
          "Effect": "Allow",
          "Principal": {
              "AWS": "${aws_cloudfront_origin_access_identity.oai.iam_arn}"
          },
          "Action": "s3:GetObject",
          "Resource": "arn:aws:s3:::${aws_s3_bucket.www_jeremychase_io.id}/*"
      }
  ]
}
POLICY
}

resource "aws_iam_role" "codebuild" {
  name = "codebuild"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# BUG(medium) rename terraform resource
data "aws_iam_policy" "CloudWatchLogsFullAccess" {
  arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# BUG(medium) too broad
# BUG(high) wrong resource name
resource "aws_iam_role_policy_attachment" "sto-readonly-role-policy-attach" {
  role       = aws_iam_role.codebuild.name
  policy_arn = data.aws_iam_policy.CloudWatchLogsFullAccess.arn
}

# BUG(medium) too broad
# BUG(medium) poor resource name
resource "aws_iam_role_policy_attachment" "s3_bucket_policy_attach" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.s3_bucket_policy.arn
}


resource "aws_codebuild_project" "www_jeremychase_io" {
  name           = "www-jeremychase-io"
  description    = "Build www.jeremychase.io"
  build_timeout  = "5"
  queued_timeout = "5"

  service_role = aws_iam_role.codebuild.arn

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

    # BUG(high) fix
    # encryption_key {
    #   id   = data.aws_kms_alias.s3kmskey.arn
    #   type = "KMS"
    # }
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

      configuration = {
        Owner      = "JeremyChase"
        Repo       = "www.jeremychase.io"
        Branch     = "master"
        OAuthToken = var.github_token # BUG(medium) determine required permissions https://github.com/settings/tokens
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

  # BUG(high) invalidate
}

resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

# BUG(high) this is duplicated
# BUG(medium) poor resource name
resource "aws_iam_policy" "s3_bucket_policy" {
  name = "s3_bucket_policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.www_jeremychase_io_codepipeline_bucket.arn}",
        "${aws_s3_bucket.www_jeremychase_io_codepipeline_bucket.arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline_policy"
  role = aws_iam_role.codepipeline_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObjectVersionAcl",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.www_jeremychase_io_codepipeline_bucket.arn}",
        "${aws_s3_bucket.www_jeremychase_io_codepipeline_bucket.arn}/*",
        "${aws_s3_bucket.www_jeremychase_io.arn}",
        "${aws_s3_bucket.www_jeremychase_io.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# BUG(high) fix
# data "aws_kms_alias" "s3kmskey" {
#   name = "alias/myKmsKey"
# }
