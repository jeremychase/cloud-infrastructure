# BUG(medium) Update to terraform 0.13

terraform {
  # BUG(medium) no locking
  backend "s3" {
    bucket = "terraform.aws.jeremychase.io" # BUG(medium) Need to document
    key    = "terraform.state"
    region = "us-east-1"
  }

  required_providers {
    aws    = "3.2.0"
    google = "~> 3.9"
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

provider "google" {
  credentials = file("~/.config/jeremychase-io-4e1d78f64f8d.json") # BUG(medium)
  project     = "jeremychase-io"
  region      = "us-east1"
}

resource "google_compute_instance" "gcp_free" {
  machine_type = "f1-micro"
  name         = "instance-1"

  boot_disk {
    auto_delete = true
    device_name = "instance-1"
    mode        = "READ_WRITE"
    source      = "https://www.googleapis.com/compute/v1/projects/jeremychase-io/zones/us-east1-b/disks/instance-1"

    initialize_params {
      image  = "https://www.googleapis.com/compute/v1/projects/debian-cloud/global/images/debian-9-stretch-v20190116"
      labels = {}
      size   = 30
      type   = "pd-standard"
    }
  }

  network_interface {
    network            = "https://www.googleapis.com/compute/v1/projects/jeremychase-io/global/networks/default"
    network_ip         = "10.142.0.2"
    subnetwork         = "https://www.googleapis.com/compute/v1/projects/jeremychase-io/regions/us-east1/subnetworks/default"
    subnetwork_project = "jeremychase-io"

    access_config {
      nat_ip       = "104.196.16.178"
      network_tier = "PREMIUM"
    }
  }

  service_account {
    email = "845966985833-compute@developer.gserviceaccount.com"
    scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
    ]
  }

  lifecycle {
    prevent_destroy = true
  }

}

resource "aws_route53_record" "us-east1_gcp_jeremychase_io_a" {
  zone_id = aws_route53_zone.jeremychase_io.zone_id
  name    = "us-east1.gcp.jeremychase.io."
  records = [
    "${google_compute_instance.gcp_free.network_interface[0].access_config[0].nat_ip}",
  ]
  ttl  = 300
  type = "A"
}

resource "aws_route53_record" "gcp_jeremychase_io_cname" {
  zone_id = aws_route53_zone.jeremychase_io.zone_id
  name    = "gcp.jeremychase.io."
  records = [
    "${aws_route53_record.us-east1_gcp_jeremychase_io_a.name}",
  ]
  ttl  = 300
  type = "CNAME"
}
