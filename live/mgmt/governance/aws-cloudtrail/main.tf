terraform {
  # BUG(medium) no locking
  backend "s3" {
    bucket = "terraform.aws.jeremychase.io"
    key    = "live/mgmt/governance/aws-cloudtrail"
    region = "us-east-1"
  }


  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.14.0"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

module "aws-cloudtrail" {
  source = "../../../../modules/governance/aws-cloudtrail"

  cloudtrail_name            = "global"
  s3_bucket_name             = "cloudtrail.aws.jeremychase.io"
  object_lock_retention_days = 30 # BUG(low) increase after verification of size and that expire lifecycle is working
}
