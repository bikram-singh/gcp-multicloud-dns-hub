variable "project_id" {
  description = "GCP project that hosts the DNS hub."
  type        = string
}

variable "region" {
  description = "Region for the hub subnet, NAT and test VM."
  type        = string
  default     = "asia-south1"
}

variable "zone" {
  description = "Zone for the test VM."
  type        = string
  default     = "asia-south1-a"
}

variable "domain" {
  description = "Base domain owned by you (no trailing dot)."
  type        = string
  default     = "gcpcloudhub.in"
}

variable "gcp_subdomain" {
  description = "Subdomain owned by GCP. Private zone is <gcp_subdomain>.<domain>."
  type        = string
  default     = "gcp"
}

variable "network_name" {
  description = "Name of the hub VPC."
  type        = string
  default     = "hub-vpc"
}

variable "subnet_cidr" {
  description = "CIDR of the hub subnet. Inbound DNS forwarder IPs are allocated from here."
  type        = string
  default     = "10.10.0.0/24"
}

variable "remote_ranges" {
  description = "CIDR ranges of AWS, Azure and on-prem that are allowed to query DNS in the hub."
  type        = list(string)
  default     = ["10.20.0.0/16", "10.30.0.0/16", "10.40.0.0/16"]
}

variable "forwarding_zones" {
  description = <<-EOT
    Private forwarding zones. Key is a short name, value has the DNS name (with trailing dot)
    and the DNS server IPs in the remote environment. Leave empty until the AWS, Azure and
    on-prem DNS servers exist.
  EOT
  type = map(object({
    dns_name   = string
    target_ips = list(string)
  }))
  default = {}
}

variable "test_records" {
  description = "A records created in the GCP private zone for testing (name => IP)."
  type        = map(string)
  default = {
    app1 = "10.10.0.50"
    app2 = "10.10.0.51"
  }
}

variable "create_public_zone" {
  description = "Create a public Cloud DNS zone for the base domain. Leave false if one already exists."
  type        = bool
  default     = false
}

variable "enable_dnssec" {
  description = "Enable DNSSEC on the public zone (only used when create_public_zone is true)."
  type        = bool
  default     = false
}

variable "create_test_vm" {
  description = "Create a small VM (no public IP) for running dig tests."
  type        = bool
  default     = true
}

variable "enable_nat" {
  description = "Create Cloud NAT so the test VM can install dnsutils. Turn off if the VM is not needed."
  type        = bool
  default     = true
}
