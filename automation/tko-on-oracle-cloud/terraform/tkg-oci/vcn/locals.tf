locals {

  default_subnets = {
    compute = {
      cidr_block = module.subnet_addrs.network_cidr_blocks["compute"]
      name       = "compute"
      type       = "private"
    },
    control-plane-endpoint = {
      cidr_block = module.subnet_addrs.network_cidr_blocks["control_plane_endpoint"]
      name       = "control-plane-endpoint"
      type       = var.public_control_plane_endpoint ? "public" : "private"
    },

    private-services = {
      cidr_block = module.subnet_addrs.network_cidr_blocks["private_services"]
      name       = "private-services"
      type       = "private"
    }
  }

  public_services_subnet = {
    public_services_subnet = {
      cidr_block = module.subnet_addrs.network_cidr_blocks["public_services"]
      name       = "public-services"
      type       = "public"
  } }

  tanzu_subnets = var.create_public_services_subnet ? merge(local.default_subnets, local.public_services_subnet) : local.default_subnets
  subnets       = merge(local.tanzu_subnets, var.additional_subnets)
  //subnets = toset(flatten(local.tanzu_subnets))

  vcn_cidr_size = parseint(split("/", var.vcn_cidr)[1], 10)
}
