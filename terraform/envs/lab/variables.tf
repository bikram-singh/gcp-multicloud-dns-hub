variable "project_id" {
  description = "GCP project ID for the lab."
  type        = string
}

variable "region" {
  type    = string
  default = "asia-south1"
}

variable "zone" {
  type    = string
  default = "asia-south1-a"
}

variable "domain" {
  type    = string
  default = "gcpcloudhub.in"
}

variable "create_public_zone" {
  description = "Set true only if no public zone for the domain exists in this project."
  type        = bool
  default     = false
}

variable "enable_dnssec" {
  type    = bool
  default = false
}

variable "create_test_vm" {
  type    = bool
  default = true
}

variable "enable_nat" {
  type    = bool
  default = true
}

variable "forwarding_zones" {
  type = map(object({
    dns_name   = string
    target_ips = list(string)
  }))
  default = {}
}
