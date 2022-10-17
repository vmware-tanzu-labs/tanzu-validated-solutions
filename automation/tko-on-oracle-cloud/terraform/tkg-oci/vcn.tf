module "vcn" {
  count                         = var.create_vcn ? 1 : 0
  source                        = "./vcn"
  region                        = var.region
  compartment_id                = var.compartment_id
  label_prefix                  = var.label_prefix
  freeform_tags                 = var.freeform_tags
  defined_tags                  = var.defined_tags
  create_internet_gateway       = var.create_internet_gateway
  create_nat_gateway            = var.create_nat_gateway
  create_service_gateway        = var.create_service_gateway
  additional_subnets            = var.additional_subnets
  nat_gateway_public_ip_id      = var.nat_gateway_public_ip_id
  vcn_name                      = var.vcn_name
  lockdown_default_seclist      = var.lockdown_default_seclist
  vcn_dns_label                 = var.vcn_dns_label
  internet_gateway_display_name = var.internet_gateway_display_name
  local_peering_gateways        = var.local_peering_gateways
  nat_gateway_display_name      = var.nat_gateway_display_name
  service_gateway_display_name  = var.service_gateway_display_name
  internet_gateway_route_rules  = var.internet_gateway_route_rules
  nat_gateway_route_rules       = var.nat_gateway_route_rules
  public_control_plane_endpoint = var.public_control_plane_endpoint
  create_public_services_subnet = var.create_public_services_subnet
}
