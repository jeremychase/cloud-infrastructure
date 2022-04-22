terraform {
  # BUG(medium) no locking
  backend "s3" {
    bucket = "terraform.aws.jeremychase.io"
    key    = "live/mgmt/services/aws-spot"
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

resource "aws_default_subnet" "us_east_1c" {
  availability_zone = "us-east-1c"

  tags = {
    Name = "us-east-1c"
  }
}

resource "aws_security_group" "spot" {
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
  name   = "spot"
  tags   = {}
  vpc_id = aws_default_vpc.default.id

  timeouts {}
}

resource "aws_network_interface" "spot" {
  security_groups = [aws_security_group.spot.id]
  subnet_id       = aws_default_subnet.us_east_1c.id

  tags = {
    Name = "spot"
  }
}

resource "aws_spot_instance_request" "spot" {
  # ami           = "ami-04505e74c0741db8d" # us-east-1 Canonical, Ubuntu, 20.04 LTS, amd64 focal image build on 2021-11-29
  # instance_type = "t3a.large"

  ami = "ami-0c582118883b46f4f" # us-east-1 - arm64 Amazon Linux 2. 4.x kernel
  #ami            = "ami-0b49a4a6e8e22fa16" # us-east-1 - arm64 Ubuntu 20.04 LTS. 5.11.x kernel
  # ami           = "ami-028c98d9274336455" # us-east-1 - arm64 Ubuntu 22.04 LTS. (Jammy) 5.15.x kernel
  instance_type = "t4g.nano"
  key_name      = "jchase-jeremychase-us-east-1"
  ebs_optimized = true

  spot_price = "0.04"

  network_interface {
    network_interface_id = aws_network_interface.spot.id
    device_index         = 0
  }

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = false
  }

  credit_specification {
    cpu_credits = "unlimited"
  }

  // https://github.com/hashicorp/terraform/issues/3263
  //
  // Applies tag to the spot *request*
  tags = {
    Name = "testing"
  }
}

resource "aws_eip" "spot" {
  vpc = true

  tags = {
    Name = "spot"
  }
}

resource "aws_eip_association" "spot" {
  allocation_id        = aws_eip.spot.id
  network_interface_id = aws_network_interface.spot.id
}

data "aws_route53_zone" "selected" {
  name = "${var.zone_name}."
}

resource "aws_route53_record" "eip_cname" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "spot.aws.${var.zone_name}."
  records = [
    aws_eip.spot.public_dns,
  ]
  ttl  = 300
  type = "CNAME"
}
