terraform {
  # BUG(medium) no locking
  backend "s3" {
    bucket = "terraform.aws.jeremychase.io"
    key    = "live/mgmt/services/aws-bastion"
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
  profile = "jeremychase"
  region  = "us-east-1"
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_security_group" "bastion" {
  description = "bastion access"
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
      description = "ping"
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
      description = "ssh"
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
    {
      cidr_blocks = [
        "0.0.0.0/0",
      ]
      description = "mosh"
      from_port   = 60000
      to_port     = 61000
      ipv6_cidr_blocks = [
        "::/0",
      ]
      prefix_list_ids = []
      protocol        = "udp"
      security_groups = []
      self            = false
    },

  ]
  name   = "bastion"
  tags   = {}
  vpc_id = aws_default_vpc.default.id

  timeouts {}
}

resource "aws_instance" "bastion" {
  #ami            = "ami-0b49a4a6e8e22fa16" # us-east-1 - arm64 Ubuntu 20.04 LTS. 5.11.x kernel
  #ami           = "ami-028c98d9274336455" # us-east-1 - arm64 Ubuntu 22.04 LTS. (Jammy) 5.15.x kernel
  # ami           = "ami-0c582118883b46f4f" # us-east-1 - arm64 Amazon Linux 2. 4.x kernel
  ami           = "ami-0e6694e5116a0086f" # us-east-1 - arm64 Debian 11 (20230124-1270)
  instance_type = "t4g.nano"
  key_name      = "jchase-jeremychase-us-east-1"
  ebs_optimized = true

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  security_groups = [aws_security_group.bastion.name]

  credit_specification {
    cpu_credits = "unlimited"
  }

  tags = {
    Name = "bastion"
  }
}

resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  vpc      = true
}

data "aws_route53_zone" "selected" {
  name = "${var.zone_name}."
}

resource "aws_route53_record" "eip_cname" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "us-east-1.aws.${var.zone_name}."
  records = [
    aws_eip.bastion.public_dns,
  ]
  ttl  = 300
  type = "CNAME"
}

resource "aws_route53_record" "short_cname" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "aws.${var.zone_name}."
  records = [
    aws_route53_record.eip_cname.name,
  ]
  ttl  = 300
  type = "CNAME"
}
