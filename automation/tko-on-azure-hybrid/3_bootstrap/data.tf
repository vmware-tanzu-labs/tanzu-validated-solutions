# data azurerm_client_config "this" {}

data "azurerm_subscription" "this" {
  subscription_id = var.sub_id
}

data "azurerm_subnet" "this" {
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.netsec_resource_group
}

data "azurerm_storage_account" "bootdiag" {
  name                = var.boot_diag_sa_name
  resource_group_name = var.netsec_resource_group
}