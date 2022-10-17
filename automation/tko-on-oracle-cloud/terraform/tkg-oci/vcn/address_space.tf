module "subnet_addrs" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = var.vcn_cidr
  networks = [
    {
      name     = "compute"
      new_bits = 2
    },
    {
      name     = "private_services"
      new_bits = 3
    },
    {
      name     = "public_services"
      new_bits = 3
    },
    {
      # control plane endpoint network is a static /29
      name     = "control_plane_endpoint"
      new_bits = 29 - local.vcn_cidr_size
    },
  ]
}
