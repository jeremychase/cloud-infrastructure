terraform {
  # BUG(medium) no locking
  backend "s3" {
    bucket = "terraform.aws.jeremychase.io"
    key    = "live/mgmt/services/aws-argocd-dev"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.14"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_security_group" "argocd_dev" {
  description = "Allow ssh"
  egress = [
    {
      cidr_blocks = [
        "0.0.0.0/0",
      ]
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    },
  ]
  ingress = [
    {
      cidr_blocks = [
        "0.0.0.0/0",
      ]
      description = ""
      from_port   = -1
      ipv6_cidr_blocks = [
        "::/0",
      ]
      prefix_list_ids = []
      protocol        = "icmp"
      security_groups = []
      self            = false
      to_port         = -1
    },
    {
      cidr_blocks = [
        "0.0.0.0/0",
      ]
      description = ""
      from_port   = 22
      ipv6_cidr_blocks = [
        "::/0",
      ]
      prefix_list_ids = []
      protocol        = "tcp"
      security_groups = []
      self            = false
      to_port         = 22
    },
  ]
  name   = "argocd_dev"
  tags   = {}
  vpc_id = aws_default_vpc.default.id

  timeouts {}
}

resource "aws_instance" "argocd_dev" {
  ami           = "ami-04505e74c0741db8d" # us-east-1 Canonical, Ubuntu, 20.04 LTS, amd64 focal image build on 2021-11-29
  instance_type = "t3a.large"
  key_name      = "jchase-jeremychase-us-east-1"
  ebs_optimized = true

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  security_groups = [aws_security_group.argocd_dev.name]

  credit_specification {
    cpu_credits = "unlimited"
  }

  tags = {
    Name = "argocd-dev"
  }
}

resource "aws_eip" "argocd_dev" {
  instance = aws_instance.argocd_dev.id
  vpc      = true
}

data "aws_route53_zone" "selected" {
  name = "${var.zone_name}."
}

resource "aws_route53_record" "eip_cname" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "argocd-dev.${var.zone_name}."
  records = [
    aws_eip.argocd_dev.public_dns,
  ]
  ttl  = 300
  type = "CNAME"
}
