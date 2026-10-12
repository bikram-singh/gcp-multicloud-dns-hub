output "gcp_private_zone" {
  value = module.gcp_hub.gcp_private_zone
}

output "public_zone_name_servers" {
  value = module.gcp_hub.public_zone_name_servers
}

output "inbound_forwarder_lookup_command" {
  value = module.gcp_hub.inbound_forwarder_lookup_command
}

output "test_vm_ssh_command" {
  value = module.gcp_hub.test_vm_ssh_command
}
