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
      name               = "medium-worker-pool"
      machine_type       = "e2-medium"
      node_locations     = "${var.region}-a" # Using one zone makes autoscaling granualirty easier.
      min_count          = 0
      max_count          = 3
      local_ssd_count    = 0
      disk_size_gb       = 10
      disk_type          = "pd-standard"
      image_type         = "COS_CONTAINERD"
      auto_repair        = true
      auto_upgrade       = true
      preemptible        = false
      spot               = true
      initial_node_count = 0
    },
    {
      name               = "small-worker-pool"
      machine_type       = "e2-small"
      node_locations     = "${var.region}-a" # Using one zone makes autoscaling granualirty easier.
      min_count          = 0
      max_count          = 6
      local_ssd_count    = 0
      disk_size_gb       = 10
      disk_type          = "pd-standard"
      image_type         = "COS_CONTAINERD"
      auto_repair        = true
      auto_upgrade       = true
      preemptible        = false
      spot               = true
      initial_node_count = 0
    },
  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  node_pools_labels = {
    all = {}

    medium-worker-pool = {
      medium-worker-pool = true
    }
  }

  node_pools_metadata = {
    all = {}
  }

  node_pools_taints = {
    all = []

    medium-worker-pool = [
      {
        key    = "medium-worker-pool"
        value  = true
        effect = "PREFER_NO_SCHEDULE"
      },
    ]
  }

  node_pools_tags = {
    all = []

    medium-worker-pool = [
      "medium-worker-pool",
    ]
  }
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

# used with external-dns
resource "google_service_account" "external-dns" {
  account_id   = "external-dns"
  display_name = "external-dns"
}

# used with external-dns
resource "google_project_iam_binding" "project" {
  project = var.project_id
  role    = "roles/dns.admin"

  members = [
    "serviceAccount:${google_service_account.external-dns.email}",
  ]
}

# used with external-dns
resource "google_service_account_iam_binding" "external-dns" {
  service_account_id = google_service_account.external-dns.id
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[external-dns/external-dns]",
  ]
}
