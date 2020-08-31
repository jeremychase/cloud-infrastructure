output "instance_external_ip_addr" {
  value = google_compute_instance.free.network_interface.0.access_config.0.nat_ip
}
