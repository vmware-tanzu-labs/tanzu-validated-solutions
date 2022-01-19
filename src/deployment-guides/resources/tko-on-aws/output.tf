output "tkg_mgmt_config" {
  value = templatefile("./mgmt.tpl",
    {
      region        = var.aws_region,
      priv_subnet_a = module.control_plane.priv_subnet_a,
      priv_subnet_b = module.control_plane.priv_subnet_b
      priv_subnet_c = module.control_plane.priv_subnet_c,
      pub_subnet_a  = module.control_plane.pub_subnet_a,
      pub_subnet_b  = module.control_plane.pub_subnet_b,
      pub_subnet_c  = module.control_plane.pub_subnet_c,
      vpc_id        = module.control_plane.vpc_id
      az1           = module.control_plane.az1,
      az2           = module.control_plane.az2,
      az3           = module.control_plane.az3
      # vnet = module.mgmt.vnet,
      # cp_subnet = module.mgmt.cp_subnet,
      # nodes_subnet = module.mgmt.nodes_subnet,
      # cp_sg = module.mgmt.cp_sg,
      # nodes_sg = module.mgmt.nodes_sg,
      # cp_machine_type = var.cp_machine_type,
      # node_machine_type = var.node_machine_type,
      # ssh_key = base64encode(var.ssh_public_key)
  })
  sensitive = true
}

output "ssh_cmd" {
  value = "ssh ubuntu@${module.control_plane.jumpbox_dns[0]} -i ${var.jb_key_file}"
}

# output "tkg_guest_config" {
#   value = templatefile("./workload.tpl",
#   { 
#           region = var.aws_region
#     # rg = module.workload-1.rg,
#     # cp_subnet = module.workload-1.cp_subnet,
#     # nodes_subnet = module.workload-1.nodes_subnet,
#     # cp_sg = module.workload-1.cp_sg,
#     # nodes_sg = module.workload-1.nodes_sg
#   })
# }