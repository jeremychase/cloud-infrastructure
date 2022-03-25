variable "google_provider_credentials_path" {
  description = "Path on local filesystem to google credentials json"
  default     = "/gcp-credentials.json"
}

variable "project_id" {
  description = "GCP project ID."
  default     = "jeremychase-io"
}

variable "region" {
  default = "us-central1"
}
