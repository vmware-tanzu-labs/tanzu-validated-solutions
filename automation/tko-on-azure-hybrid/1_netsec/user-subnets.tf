locals {
  tkgm_admin_net    = "10.0.0.0/28"
  tkgm_mgmtnode_net = "10.0.0.64/26"
  tkgm_mgmtctrl_net = "10.0.0.192/26"
  tkgm_wrkctrl_net  = "10.0.0.16/28"
  tkgm_wrknode_net  = "10.0.0.128/26"
}

#===================
#   TKGM Management Cluster Tier
#===================
module "tkgm_node" {
  source        = "../modules/node_subnet"
  local_data    = local.local_data
  flow_log_data = module.vnet_base.flow_log_data
  subnet_settings = {
    "TKGM-MgmtNode" = { "network" = local.tkgm_mgmtnode_net, "service_endpoints" = [], "allow_plink_endpoints" = false }
    "TKGM-WorkloadNode" = { "network" = local.tkgm_wrknode_net, "service_endpoints" = [], "allow_plink_endpoints" = false }
  }
}

module "general_tier" {
  source        = "../modules/general_subnet"
  local_data    = local.local_data
  flow_log_data = module.vnet_base.flow_log_data
  subnet_settings = {
    "TKGM-MgmtCtrl"     = { "network" = local.tkgm_mgmtctrl_net, "service_endpoints" = [], "allow_plink_endpoints" = false }
    "TKGM-Admin"        = { "network" = local.tkgm_admin_net, "service_endpoints" = [], "allow_plink_endpoints" = true }
    "TKGM-WorkloadCtrl" = { "network" = local.tkgm_wrkctrl_net, "service_endpoints" = [], "allow_plink_endpoints" = false }
  }
}