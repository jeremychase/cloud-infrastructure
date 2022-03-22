terraform {
  # BUG(medium) no locking
  backend "s3" {
    bucket = "terraform.aws.jeremychase.io"
    key    = "live/mgmt/services/gcp-free-tier_bastion"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.14.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 3.9"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

provider "google" {
  credentials = file(var.google_provider_credentials_path)
  project     = "jeremychase-io"
  region      = "us-east1"
}

# BUG(low) check bill
# BUG(low) split into module
resource "google_compute_instance" "free" {
  machine_type = "e2-micro"
  name         = "free"
  zone         = "us-east1-b"

  boot_disk {
    auto_delete = true

    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 30
      type  = "pd-standard"
    }
  }

  metadata = {
    startup-script = file("${path.module}/files/debian-11-startup.sh")
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

  lifecycle {
    prevent_destroy = false
  }
}

data "aws_route53_zone" "selected" {
  name = "${var.zone_name}."
}

resource "aws_route53_record" "a_record" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "us-east1.gcp.${var.zone_name}."
  records = [
    google_compute_instance.free.network_interface[0].access_config[0].nat_ip,
  ]
  ttl  = 300
  type = "A"
}

resource "aws_route53_record" "cname" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "gcp.${var.zone_name}."
  records = [
    aws_route53_record.a_record.name,
  ]
  ttl  = 300
  type = "CNAME"
}
