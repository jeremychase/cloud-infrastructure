# used with external-dns
terraform {
  # BUG(medium) no locking
  backend "s3" {
    bucket = "terraform.aws.jeremychase.io"
    key    = "live/mgmt/dns-zones/mgmt-jeremychase-io"
    region = "us-east-1"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.15"
    }
  }
}

provider "google" {
  credentials = file(var.google_provider_credentials_path)
  project     = var.project_id
  region      = var.region
}

# google_client_config and kubernetes provider must be explicitly specified like the following.
data "google_client_config" "default" {}

resource "google_dns_managed_zone" "mgmt-jeremychase-io" {
  name        = "${var.subdomain}-${replace(var.zone_name, ".", "-")}"
  dns_name    = "${var.subdomain}.${var.zone_name}."
  description = "${var.subdomain}.${var.zone_name}"
}

data "aws_route53_zone" "selected" {
  name = "${var.zone_name}."
}

resource "aws_route53_record" "mgmt-jeremychase-io" {
  # allow_overwrite = true
  name    = "${var.subdomain}.${var.zone_name}."
  ttl     = 300
  type    = "NS"
  zone_id = data.aws_route53_zone.selected.zone_id

  records = [
    google_dns_managed_zone.mgmt-jeremychase-io.name_servers[0],
    google_dns_managed_zone.mgmt-jeremychase-io.name_servers[1],
    google_dns_managed_zone.mgmt-jeremychase-io.name_servers[2],
    google_dns_managed_zone.mgmt-jeremychase-io.name_servers[3],
  ]
}
