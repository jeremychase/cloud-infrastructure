terraform {
  backend "s3" {
    bucket = "terraform.aws.jeremychase.io" # BUG(hardcoded) Need to document
    key    = "terraform.state"
    region = "us-east-1"
  }

  required_providers {
    aws    = "~> 2.48"
    google = "~> 3.9"
    vultr  = "~> 1.1"
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

provider "google" {
  credentials = file("~/.config/jeremychase-io-4e1d78f64f8d.json") # BUG(hardcoded)
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

}

# google_dns_managed_zone.jeremychase-io:
resource "google_dns_managed_zone" "jeremychase-io" {
  dns_name   = "jeremychase.io."
  labels     = {}
  name       = "jeremychase-io"
  project    = "jeremychase-io"
  visibility = "public"

  dnssec_config {
    kind          = "dns#managedZoneDnsSecConfig"
    non_existence = "nsec3"
    state         = "on"

    default_key_specs {
      algorithm  = "rsasha256"
      key_length = 2048
      key_type   = "keySigning"
      kind       = "dns#dnsKeySpec"
    }
    default_key_specs {
      algorithm  = "rsasha256"
      key_length = 1024
      key_type   = "zoneSigning"
      kind       = "dns#dnsKeySpec"
    }
  }

  timeouts {}
}

resource "google_dns_record_set" "jeremychase_io_ns" {
  managed_zone = "jeremychase-io"
  name         = "jeremychase.io."
  project      = "jeremychase-io"
  rrdatas = [
    "ns-cloud-e1.googledomains.com.",
    "ns-cloud-e2.googledomains.com.",
    "ns-cloud-e3.googledomains.com.",
    "ns-cloud-e4.googledomains.com.",
  ]
  ttl  = 21600
  type = "NS"
}

resource "google_dns_record_set" "jeremychase_io_soa" {
  managed_zone = "jeremychase-io"
  name         = "jeremychase.io."
  project      = "jeremychase-io"
  rrdatas = [
    "ns-cloud-e1.googledomains.com. cloud-dns-hostmaster.google.com. 155 21600 3600 259200 300",
  ]
  ttl  = 21600
  type = "SOA"
}

resource "google_dns_record_set" "jeremychase_io_txt" {
  managed_zone = "jeremychase-io"
  name         = "jeremychase.io."
  project      = "jeremychase-io"
  rrdatas = [
    "\"google-site-verification=vPzG3kKAwhKTwMs6oxxu9VO6NSNduoY5GACvhnpxeXs\"",
  ]
  ttl  = 300
  type = "TXT"
}

resource "google_dns_record_set" "us-east1_gcp_jeremychase_io_a" {
  managed_zone = "jeremychase-io"
  name         = "us-east1.gcp.jeremychase.io."
  project      = "jeremychase-io"
  rrdatas = [
    "${google_compute_instance.gcp_free.network_interface[0].access_config[0].nat_ip}",
  ]
  ttl  = 300
  type = "A"
}

resource "google_dns_record_set" "gcp_jeremychase_io_cname" {
  managed_zone = "jeremychase-io"
  name         = "gcp.jeremychase.io."
  project      = "jeremychase-io"
  rrdatas = [
    "${google_dns_record_set.us-east1_gcp_jeremychase_io_a.name}",
  ]
  ttl  = 300
  type = "CNAME"
}

# Configure the Vultr Provider
# provider "vultr" {
# }

# resource "vultr_server" "nj-medium" {
#   plan_id     = 203
#   os_id       = 365
#   region_id   = 1
#   ssh_key_ids = ["5b08514fa6d1a"]
# }

# resource "google_dns_record_set" "nj_vultr_jeremychase_io_a" {
#   managed_zone = "jeremychase-io"
#   name         = "nj.vultr.jeremychase.io."
#   project      = "jeremychase-io"
#   rrdatas = [
#     "${vultr_server.nj-medium.main_ip}",
#   ]
#   ttl  = 300
#   type = "A"
# }

resource "google_dns_record_set" "www_jeremychase_io_cname" {
  managed_zone = "jeremychase-io"
  name         = "www.jeremychase.io."
  project      = "jeremychase-io"
  rrdatas = [
    "ingress.lamp.app.",
  ]
  ttl  = 300
  type = "CNAME"
}

