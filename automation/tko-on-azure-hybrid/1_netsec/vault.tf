data "azurerm_key_vault" "this" {
  name                = var.vault_name
  resource_group_name = var.vault_resource_group_name
}

resource "azurerm_key_vault_secret" "AZURE_CONTROL_PLANE_SUBNET_CIDR" {
  name         = "AZURE-CONTROL-PLANE-SUBNET-CIDR"
  value        = local.tkgm_mgmtctrl_net
  key_vault_id = data.azurerm_key_vault.this.id
}

resource "azurerm_key_vault_secret" "AZURE_CONTROL_PLANE_SUBNET_NAME" {
  name         = "AZURE-CONTROL-PLANE-SUBNET-NAME"
  value        = element([for subnet in keys(module.general_tier.subnets) : subnet if length(regexall("mgmt", lower(subnet))) > 0], 0)
  key_vault_id = data.azurerm_key_vault.this.id
}

resource "azurerm_key_vault_secret" "AZURE_NODE_SUBNET_NAME" {
  name         = "AZURE-NODE-SUBNET-NAME"
  value        = element([for subnet in keys(module.tkgm_node.subnets) : subnet if length(regexall("mgmt", lower(subnet))) > 0], 0)
  key_vault_id = data.azurerm_key_vault.this.id
}

resource "azurerm_key_vault_secret" "AZURE_LOCATION" {
  name         = "AZURE-LOCATION"
  value        = element([for subnet in keys(module.tkgm_node.subnets) : subnet if length(regexall("worker", lower(subnet))) > 0], 0)
  key_vault_id = data.azurerm_key_vault.this.id
}

resource "azurerm_key_vault_secret" "AZURE_FRONTEND_PRIVATE_IP" {
  name         = "AZURE-FRONTEND-PRIVATE-IP"
  value        = cidrhost(local.tkgm_mgmtctrl_net, 4)
  key_vault_id = data.azurerm_key_vault.this.id
}

resource "azurerm_key_vault_secret" "AZURE_NODE_SUBNET_CIDR" {
  name         = "AZURE-NODE-SUBNET-CIDR"
  value        = local.tkgm_mgmtnode_net
  key_vault_id = data.azurerm_key_vault.this.id
}

resource "azurerm_key_vault_secret" "AZURE_SUBSCRIPTION_ID" {
  name         = "AZURE-SUBSCRIPTION-ID"
  value        = var.sub_id
  key_vault_id = data.azurerm_key_vault.this.id
}

resource "azurerm_key_vault_secret" "AZURE_TENANT_ID" {
  name         = "AZURE-TENANT-ID"
  value        = var.sub_id
  key_vault_id = data.azurerm_key_vault.this.id
}

resource "azurerm_key_vault_secret" "AZURE_VNET_CIDR" {
  name         = "AZURE-VNET-CIDR"
  value        = var.core_address_space
  key_vault_id = data.azurerm_key_vault.this.id
}

resource "azurerm_key_vault_secret" "AZURE_VNET_NAME" {
  name         = "AZURE-VNET-NAME"
  value        = module.vnet_base.vnet_name
  key_vault_id = data.azurerm_key_vault.this.id
}

resource "azurerm_key_vault_secret" "AZURE_VNET_RESOURCE_GROUP" {
  name         = "AZURE-VNET-RESOURCE-GROUP"
  value        = azurerm_resource_group.rg.name
  key_vault_id = data.azurerm_key_vault.this.id
}