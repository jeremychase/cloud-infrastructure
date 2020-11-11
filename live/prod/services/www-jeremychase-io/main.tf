terraform {
  # BUG(medium) no locking
  backend "s3" {
    bucket = "terraform.aws.jeremychase.io" # BUG(medium) Need to document
    key    = "live/prod/services/www-jeremychase-io"
    region = "us-east-1"
  }

  required_version = "~> 0.12.24" # BUG(medium) Update to terraform 0.13

  required_providers {
    archive = "~> 1.3"
    aws     = "3.14.0"
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

data "aws_route53_zone" "selected" {
  name = "${var.zone_name}."
}
