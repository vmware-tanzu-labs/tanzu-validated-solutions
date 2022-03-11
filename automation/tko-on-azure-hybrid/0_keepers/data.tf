data "azurerm_subscription" "this" {
  subscription_id = var.sub_id
}

data "azurerm_client_config" "current" {}

data "azuread_group" "this" {
  count = var.acl_group != "" ? 1 : 0

  display_name = var.acl_group
}