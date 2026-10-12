output "network_id" {
  description = "Hub VPC ID."
  value       = google_compute_network.hub.id
}

output "network_name" {
  description = "Hub VPC name."
  value       = google_compute_network.hub.name
}

output "gcp_private_zone" {
  description = "Private zone for GCP-owned names."
  value       = google_dns_managed_zone.gcp_private.dns_name
}

output "public_zone_name_servers" {
  description = "Set these as the nameservers at your domain registrar (empty when no public zone is created)."
  value       = var.create_public_zone ? google_dns_managed_zone.public[0].name_servers : []
}

output "inbound_forwarder_lookup_command" {
  description = "Run this to list the inbound DNS forwarder IPs that AWS, Azure and on-prem must forward to."
  value       = "gcloud compute addresses list --project=${var.project_id} --filter='purpose=DNS_RESOLVER' --format='value(address,subnetwork)'"
}

output "test_vm_ssh_command" {
  description = "SSH into the test VM through IAP."
  value       = var.create_test_vm ? "gcloud compute ssh dns-test-gcp --project=${var.project_id} --zone=${var.zone} --tunnel-through-iap" : ""
}
