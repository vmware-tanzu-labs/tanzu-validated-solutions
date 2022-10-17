resource "oci_network_load_balancer_network_load_balancer" "tkg" {
  #Required
  compartment_id                 = var.compartment_id
  display_name                   = "${var.vcn_name}-lb"
  subnet_id                      = var.create_vcn ? module.vcn[0].subnet_ids["control-plane-endpoint"] : var.control_plane_endpoint_subnet_id
  defined_tags                   = var.defined_tags
  freeform_tags                  = local.freeform_tags
  is_preserve_source_destination = true
  is_private                     = var.public_control_plane_endpoint ? false : true
  network_security_group_ids     = [oci_core_network_security_group.control_plane_endpoint.id]
}
