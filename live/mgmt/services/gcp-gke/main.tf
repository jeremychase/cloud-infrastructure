terraform {
  # BUG(medium) no locking
  backend "s3" {
    bucket = "terraform.aws.jeremychase.io"
    key    = "live/mgmt/services/gcp-gke"
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

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google"
  project_id                 = var.project_id
  name                       = "mgmt"
  region                     = var.region
  zones                      = ["${var.region}-a", "${var.region}-b", "${var.region}-f"]
  network                    = "gke"
  subnetwork                 = "gke"
  ip_range_pods              = "gke-pods"
  ip_range_services          = "gke-services"
  http_load_balancing        = false
  network_policy             = false
  horizontal_pod_autoscaling = true
  filestore_csi_driver       = false
  regional                   = false
  create_service_account     = true
  remove_default_node_pool   = true

  depends_on = [
    google_compute_subnetwork.gke,
  ]

  node_pools = [
    {
      name           = "default-node-pool"
      machine_type   = "e2-small"
      node_locations = "${var.region}-a,${var.region}-b"
      # node_locations  = "${var.region}-a,${var.region}-b,${var.region}-f"
      min_count       = 1
      max_count       = 1
      local_ssd_count = 0
      disk_size_gb    = 10
      disk_type       = "pd-standard"
      image_type      = "COS_CONTAINERD"
      auto_repair     = true
      auto_upgrade    = true
      # service_account    = "project-service-account@${var.project_id}.iam.gserviceaccount.com"
      preemptible        = true
      initial_node_count = 1
    },
  ]

  node_pools_oauth_scopes = {
    all = []

    default-node-pool = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  node_pools_labels = {
    all = {}

    default-node-pool = {
      default-node-pool = true
    }
  }

  node_pools_metadata = {
    all = {}

    default-node-pool = {
      node-pool-metadata-custom-value = "my-node-pool"
    }
  }

  node_pools_taints = {
    all = []

    default-node-pool = [
      {
        key    = "default-node-pool"
        value  = true
        effect = "PREFER_NO_SCHEDULE"
      },
    ]
  }

  node_pools_tags = {
    all = []

    default-node-pool = [
      "default-node-pool",
    ]
  }
}

data "aws_route53_zone" "selected" {
  name = "${var.zone_name}."
}

# BUG(high) setting this A record shouldn't be in this repo
resource "aws_route53_record" "ingress" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "argocd.${var.zone_name}"
  records = [
    var.argo_ingress_address,
  ]
  ttl  = 86400
  type = "A"
}

resource "google_compute_subnetwork" "gke" {
  name          = "gke"
  ip_cidr_range = "10.2.0.0/16"
  region        = var.region
  network       = google_compute_network.gke.id
  project       = var.project_id
  secondary_ip_range = [
    {
      range_name    = "gke-pods"
      ip_cidr_range = "192.168.0.0/18"
    },
    {
      range_name    = "gke-services"
      ip_cidr_range = "192.168.64.0/18"
    },
  ]
}

resource "google_compute_network" "gke" {
  name                    = "gke"
  auto_create_subnetworks = false
  project                 = var.project_id
}
