#---------------------------------------------
#   VNET INFORMATION
#---------------------------------------------

output "vnet_id" {
  description = "ID of this VNet.  Used for reference by other VNets for peering"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of this VNet.  Needed if additional subnets are added outside of this module."
  value       = azurerm_virtual_network.main.name
}

#------------------------------------------------------------------------
#   Log Analytics Outputs for other uses (Firewalls, etc)
#------------------------------------------------------------------------
output "flow_log_data" {
  value = {
    "law_id"           = azurerm_log_analytics_workspace.spoke.id
    "law_workspace_id" = azurerm_log_analytics_workspace.spoke.workspace_id
    "flow_log_sa_id"   = azurerm_storage_account.bootdiag.id
    "nw_name"          = "NetworkWatcher_${var.local_data.location}"
    "nw_rg_name"       = "NetworkWatcherRG"
  }
  description = <<EOF
    This map contains all of the log analytics data needed to set up NSG flow logs.  It contains the following:
    "law_id" -- Log Analytics ID
    "law_workspace_id" -- Log Analytics Workspace ID
    "flow_log_sa_id" -- Boot Diagnostics Storage Account ID (used for both boot diag and nsg flow logs)
EOF
}

output "boot_diag_url" {
  description = "The endpoint URL for blob storage in the primary location"
  value       = azurerm_storage_account.bootdiag.primary_blob_endpoint
}