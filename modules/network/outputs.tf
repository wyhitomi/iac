output "network_id" {
  description = "The ID of the VPC network."
  value       = google_compute_network.this.id
}

output "network_name" {
  description = "The name of the VPC network."
  value       = google_compute_network.this.name
}

output "subnet_ids" {
  description = "Map of subnet name to subnet ID."
  value       = { for k, v in google_compute_subnetwork.this : k => v.id }
}
