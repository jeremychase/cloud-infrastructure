variable "zone_name" {
  description = "The Route53 zone name."
  default     = "jeremychase.io" # BUG(low) make input when making this a module
}

variable "prefix" {
  description = "The prefix which should be used for Azure resources."
  default     = "bastion"
}

variable "location" {
  description = "The Azure Region in which resources."
  default     = "eastus"
}

variable "adminuser" {
  description = "The admin username"
  default = "jchase"
}

variable "adminuser_pubkey" {
  description = "The admin user's pub key from local machine"
  default     = "~/.ssh/id_rsa.pub"
}