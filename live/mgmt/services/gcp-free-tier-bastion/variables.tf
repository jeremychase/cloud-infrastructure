variable "zone_name" {
  description = "The Route53 zone name."
  default     = "jeremychase.io" # BUG(low) make input when making this a module
}

variable "project_id" {
  description = "GCP project ID."
  default     = "jeremychase-io"
}

variable "google_provider_credentials_path" {
  description = "Path on local filesystem to google credentials json"
  default     = "/gcp-credentials.json" # BUG(low) make input when making this a module
}
