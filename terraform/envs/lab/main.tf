provider "google" {
  project = var.project_id
  region  = var.region
}

module "gcp_hub" {
  source = "../../modules/gcp-hub"

  project_id = var.project_id
  region     = var.region
  zone       = var.zone
  domain     = var.domain

  create_public_zone = var.create_public_zone
  enable_dnssec      = var.enable_dnssec
  create_test_vm     = var.create_test_vm
  enable_nat         = var.enable_nat

  # Filled in later, once the AWS, Azure and on-prem DNS servers exist.
  forwarding_zones = var.forwarding_zones
}
