variable "zone_name" {
  description = "The Route53 zone name."
  default     = "jeremychase.io" # BUG(low) make input when making this a module
}

variable "google_provider_credentials_path" {
  description = "Path on local filesystem to google credentials json"
  default     = "~/.config/jeremychase-io-4e1d78f64f8d.json" # BUG(low) make input when making this a module
}
