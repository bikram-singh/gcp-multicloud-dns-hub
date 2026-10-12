locals {
  gcp_zone_dns_name = "${var.gcp_subdomain}.${var.domain}."
  gcp_zone_name     = "${var.gcp_subdomain}-${replace(var.domain, ".", "-")}-private"
}

# ---------------------------------------------------------------------------
# APIs
# ---------------------------------------------------------------------------
resource "google_project_service" "dns" {
  project            = var.project_id
  service            = "dns.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "compute" {
  project            = var.project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

# ---------------------------------------------------------------------------
# Hub network
# ---------------------------------------------------------------------------
resource "google_compute_network" "hub" {
  project                 = var.project_id
  name                    = var.network_name
  auto_create_subnetworks = false

  depends_on = [google_project_service.compute]
}

resource "google_compute_subnetwork" "hub" {
  project                  = var.project_id
  name                     = "${var.network_name}-${var.region}"
  region                   = var.region
  network                  = google_compute_network.hub.id
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true
}

# Remote environments query the inbound forwarder IPs over VPN. This rule is
# harmless if the forwarding path does not need it and makes the intent explicit.
resource "google_compute_firewall" "allow_dns_from_remote" {
  project   = var.project_id
  name      = "${var.network_name}-allow-dns-from-remote"
  network   = google_compute_network.hub.name
  direction = "INGRESS"

  source_ranges = var.remote_ranges

  allow {
    protocol = "udp"
    ports    = ["53"]
  }

  allow {
    protocol = "tcp"
    ports    = ["53"]
  }
}

# SSH to the test VM through Identity-Aware Proxy (no public IP needed).
resource "google_compute_firewall" "allow_iap_ssh" {
  project   = var.project_id
  name      = "${var.network_name}-allow-iap-ssh"
  network   = google_compute_network.hub.name
  direction = "INGRESS"

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["dns-test"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# ---------------------------------------------------------------------------
# Cloud NAT (optional) so the test VM can install packages
# ---------------------------------------------------------------------------
resource "google_compute_router" "hub" {
  count   = var.enable_nat ? 1 : 0
  project = var.project_id
  name    = "${var.network_name}-router"
  region  = var.region
  network = google_compute_network.hub.id
}

resource "google_compute_router_nat" "hub" {
  count                              = var.enable_nat ? 1 : 0
  project                            = var.project_id
  name                               = "${var.network_name}-nat"
  router                             = google_compute_router.hub[0].name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# ---------------------------------------------------------------------------
# Private zone for GCP-owned names (gcp.<domain>)
# ---------------------------------------------------------------------------
resource "google_dns_managed_zone" "gcp_private" {
  project    = var.project_id
  name       = local.gcp_zone_name
  dns_name   = local.gcp_zone_dns_name
  visibility = "private"

  description = "Private zone for GCP workloads"

  private_visibility_config {
    networks {
      network_url = google_compute_network.hub.id
    }
  }

  depends_on = [google_project_service.dns]
}

resource "google_dns_record_set" "test" {
  for_each = var.test_records

  project      = var.project_id
  managed_zone = google_dns_managed_zone.gcp_private.name
  name         = "${each.key}.${local.gcp_zone_dns_name}"
  type         = "A"
  ttl          = 300
  rrdatas      = [each.value]
}

# ---------------------------------------------------------------------------
# Inbound server policy: gives AWS, Azure and on-prem resolver IPs to forward to
# ---------------------------------------------------------------------------
resource "google_dns_policy" "inbound" {
  project                   = var.project_id
  name                      = "${var.network_name}-inbound-policy"
  description               = "Inbound DNS forwarding for the hub VPC"
  enable_inbound_forwarding = true
  enable_logging            = true

  networks {
    network_url = google_compute_network.hub.id
  }

  depends_on = [
    google_project_service.dns,
    google_compute_subnetwork.hub,
  ]
}

# ---------------------------------------------------------------------------
# Forwarding zones: send aws./azure./onprem. queries to their DNS servers
# ---------------------------------------------------------------------------
resource "google_dns_managed_zone" "forwarding" {
  for_each = var.forwarding_zones

  project    = var.project_id
  name       = "fwd-${each.key}"
  dns_name   = each.value.dns_name
  visibility = "private"

  description = "Forward ${each.value.dns_name} to the ${each.key} DNS servers"

  private_visibility_config {
    networks {
      network_url = google_compute_network.hub.id
    }
  }

  forwarding_config {
    dynamic "target_name_servers" {
      for_each = each.value.target_ips
      content {
        ipv4_address    = target_name_servers.value
        forwarding_path = "default"
      }
    }
  }

  depends_on = [google_project_service.dns]
}

# ---------------------------------------------------------------------------
# Public zone (optional): split-horizon demo for the real domain
# ---------------------------------------------------------------------------
resource "google_dns_managed_zone" "public" {
  count = var.create_public_zone ? 1 : 0

  project    = var.project_id
  name       = replace(var.domain, ".", "-")
  dns_name   = "${var.domain}."
  visibility = "public"

  description = "Public zone for ${var.domain}"

  dnssec_config {
    state = var.enable_dnssec ? "on" : "off"
  }

  depends_on = [google_project_service.dns]
}

# ---------------------------------------------------------------------------
# Test VM (optional)
# ---------------------------------------------------------------------------
resource "google_compute_instance" "test" {
  count = var.create_test_vm ? 1 : 0

  project      = var.project_id
  name         = "dns-test-gcp"
  zone         = var.zone
  machine_type = "e2-micro"
  tags         = ["dns-test"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.hub.id
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get install -y dnsutils
  EOT

  depends_on = [google_compute_router_nat.hub]
}
