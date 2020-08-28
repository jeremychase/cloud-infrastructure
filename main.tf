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

# BUG(high) split this out
# BUG(low) check bill
resource "google_compute_instance" "free" {
  machine_type = "f1-micro"
  name         = "free"
  zone         = "us-east1-b"

  boot_disk {
    auto_delete = true

    initialize_params {
      image = "debian-cloud/debian-10"
      size  = 30
      type  = "pd-standard"
    }
  }

  metadata = {
    startup-script = file("${path.module}/files/debian-10-startup.sh")
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
    prevent_destroy = true
  }
}

resource "aws_route53_record" "us-east1_gcp_jeremychase_io_a" {
  zone_id = aws_route53_zone.jeremychase_io.zone_id
  name    = "us-east1.gcp.jeremychase.io."
  records = [
    "${google_compute_instance.free.network_interface[0].access_config[0].nat_ip}",
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
