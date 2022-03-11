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
  min_tls_version           = "TLS1_2"
}

#---------------------------------------------
#  NETWORK WATCHER
#--------------------------------------------
# Enable Network Watcher in the region where this VNet is built
# ISSUE: If network watcher and RG exist, this causes problems.
#  RESOLUTION: The following approach works, but it's OS-dependent (or tool-dependent)
# data "azurerm_client_config" "current" {}

# data "external" "this" {
#   program = ["pwsh.exe", "./Get-TfObjFromAzure.ps1"]
#   query = {
#     resourceGroup   = "rg-001"
#     subscriptionId  = data.azurerm_client_config.current.subscription_id
#   }
# }

# resource "azurerm_resource_group" "nwrg" {
#   count = data.external.this.result.qty == 0 ? 0 : 1

#   name = "NetworkWatcherRG"
#   location = var.local_data.location

#   tags = var.local_data.tags
#   #   lifecycle {
#     ignore_changes = [
#       tags["StartDate"],
#     ]
#   }
# }

resource "azurerm_resource_group" "nwrg" {
  count = var.CreateNetworkWatcherRG

  name     = "NetworkWatcherRG"
  location = var.local_data.location

  tags = var.local_data.tags

  lifecycle {
    ignore_changes = [
      tags["StartDate"],
    ]
  }
}

resource "azurerm_network_watcher" "nw" {
  count = var.CreateNetworkWatcher

  name                = "NetworkWatcher_${var.local_data.location}"
  resource_group_name = "NetworkWatcherRG"
  location            = var.local_data.location

  tags = var.local_data.tags

  lifecycle {
    ignore_changes = [
      tags["StartDate"],
    ]
  }
}

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