# The following subnet definitions serve as an example demonstrating an
# administrative subnet, and pairs of management and workload cluster subnets.

# Locals define the CIDR blocks while subnet_settings within respective modules
# define values for the subnets themselves. The subnet_settings 'key' represents
# the name of the subnet as seen within Azure.
#
# Azure prefers using the list type for subnet address prefixes, however this 
# may produce unpredictable results for a TKGm CAPZ cluster implementation. 
# We can support the use of lists, but at present, only a single prefix per 
# subnet is supported.

locals {
  tkgm_admin_net    = ["10.1.2.0/28"]
  tkgm_mgmtnode_net = ["10.1.2.64/26"]
  tkgm_mgmtctrl_net = ["10.1.2.192/26"]
  tkgm_wrkctrl_net  = ["10.1.2.16/28"]
  tkgm_wrknode_net  = ["10.1.2.128/26"]
}

#===================
#   TKGM Management Cluster Tier
#===================
# TKG has assumptions about the NSG names depending on subnet roles.
# The ftwo modules below separate those assumptions.

module "node_sub" {
  source        = "../modules/node_subnet"
  local_data    = local.local_data
  flow_log_data = module.vnet_base.flow_log_data
  subnet_settings = {
    "TKGM-MgmtNode"     = { "network" = local.tkgm_mgmtnode_net, "service_endpoints" = [], "allow_plink_endpoints" = false }
    "TKGM-WorkloadNode" = { "network" = local.tkgm_wrknode_net, "service_endpoints" = [], "allow_plink_endpoints" = false }
  }
}

module "controlplane_sub" {
  source        = "../modules/controlplane_subnet"
  local_data    = local.local_data
  flow_log_data = module.vnet_base.flow_log_data
  subnet_settings = {
    "TKGM-MgmtCtrl"     = { "network" = local.tkgm_mgmtctrl_net, "service_endpoints" = [], "allow_plink_endpoints" = false }
    "TKGM-Admin"        = { "network" = local.tkgm_admin_net, "service_endpoints" = [], "allow_plink_endpoints" = true }
    "TKGM-WorkloadCtrl" = { "network" = local.tkgm_wrkctrl_net, "service_endpoints" = [], "allow_plink_endpoints" = false }
  }
}