terraform {
  # BUG(medium) no locking
  backend "s3" {
    bucket = "terraform.aws.jeremychase.io" # BUG(medium) Need to document
    key    = "terraform.state"
    region = "us-east-1"
  }

  required_version = "~> 0.12.24" # BUG(medium) Update to terraform 0.13

  required_providers {
    aws = "3.2.0"
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}
