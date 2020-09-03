variable "s3_bucket_name" {
  description = "The S3 bucket for holding CloudTrail logs."
  type        = string
}

variable "object_lock_retention_days" {
  description = "Number of days to lock events. Objects expire one day later."
  type        = number
  default     = 1
}

variable "cloudtrail_name" {
  description = "The name of the CloudTrail"
  type        = string
}
