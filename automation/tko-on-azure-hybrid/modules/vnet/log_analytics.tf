#---------------------------------------------
#  BOOT DIAG / LOG ANALYTICS STORAGE ACCOUNT
#---------------------------------------------
resource "azurerm_storage_account" "bootdiag" {
  name                      = var.boot_diag_sa_name
  resource_group_name       = var.local_data.resource_group_name
  location                  = var.local_data.location
  account_kind              = "StorageV2"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = "true"
}


#---------------------------------------------
#  NETWORK WATCHER
#--------------------------------------------
# Enable Network Watcher in the region where this VNet is built
# ISSUE: If network watcher and RG exist, this causes problems.
# resource "azurerm_resource_group" "nwrg" {
#   name     = "NetworkWatcherRG"
#   location = var.local_data.location

#   tags = var.local_data.tags

#   lifecycle {
#     ignore_changes = [
#       tags["StartDate"],
#     ]
#   }
# }

# resource "azurerm_network_watcher" "nw" {
#   name                = "NetworkWatcher_${var.local_data.location}"
#   resource_group_name = azurerm_resource_group.nwrg.name
#   location            = var.local_data.location

#   tags = var.local_data.tags

#   lifecycle {
#     ignore_changes = [
#       tags["StartDate"],
#     ]
#   }
# }

#---------------------------------------------
#  LOG ANALYTICS FOR NSG FLOW LOGS
#---------------------------------------------
resource "azurerm_log_analytics_workspace" "spoke" {
  name                = var.local_data.prefix
  location            = var.local_data.location
  resource_group_name = var.local_data.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}