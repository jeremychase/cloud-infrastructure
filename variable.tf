# BUG(high) rename file

variable "github_personal_access_token" {
  type = string
}

variable "force_destroy_s3_buckets" {
  description = "Remove all objects in S3 buckets when destroying"
  type        = bool
  default     = false
}

variable "zone_name" {
  description = "The Route53 zone name."
  default     = "jeremychase.io" # BUG(low) make input when making this a module
}
