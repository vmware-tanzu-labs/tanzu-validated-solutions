output "vcn_id" {
  description = "ID of vcn that is created"
  value       = try(module.vcn[0].vcn_id, "")
}

output "subnet_ids" {
  description = "mapping of subnets to use"
  value       = try(module.vcn[0].subnet_ids, "")
}



output "security_group_ids" {
  description = "mapping of security groups to use"
  value = {
    control_plane          = oci_core_network_security_group.control_plane.id
    workers                = oci_core_network_security_group.workers.id
    control_plane_endpoint = oci_core_network_security_group.control_plane_endpoint.id
  }
}

output "load_balancer_id" {
  description = "ID of the load balancer"
  value       = oci_network_load_balancer_network_load_balancer.tkg.id
}
