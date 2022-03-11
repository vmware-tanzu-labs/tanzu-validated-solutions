data "azurerm_key_vault" "this" {
  name                = local.vault_name
  resource_group_name = local.vault_resource_group_name
}

# The requirements for Key Vault Secret names are: Between 1 and 127
# characters long. Alphanumerics and hyphens (dash). Secrets must be
# unique within a Key Vault.Aug 20, 2021
#
# src: https://azure.github.io/PSRule.Rules.Azure/en/rules/Azure.KeyVault.SecretName/
#
#
# The following outputs to Azure Key Vault are a good example of 
# outputs that are useful in generating a cluster configuration
# for Tanzu Kubernetes Grid. You may need to modify some of these 
# depending on your version of TKG and inputs. For example, 
# AZURE_CONTROL_PLANE_SUBNET_NAME and AZURE_NODE_SUBNET_NAME 
# should reflect subnets defined within user-subnets.tf.

resource "azurerm_key_vault_secret" "AZURE_CONTROL_PLANE_SUBNET_CIDR_mgmt" {
  name         = "AZURE-CONTROL-PLANE-SUBNET-CIDR-management"
  value        = local.tkgm_mgmtctrl_net[0]
  key_vault_id = data.azurerm_key_vault.this.id
}

resource "azurerm_key_vault_secret" "AZURE_CONTROL_PLANE_SUBNET_CIDR_wrk" {
  name         = "AZURE-CONTROL-PLANE-SUBNET-CIDR-workload"
  value        = local.tkgm_wrkctrl_net[0]
  key_vault_id = data.azurerm_key_vault.this.id
}
resource "azurerm_key_vault_secret" "AZURE_CONTROL_PLANE_SUBNET_NAME_mgmt" {
  name         = "AZURE-CONTROL-PLANE-SUBNET-NAME-management"
  value        = element([for subnet in keys(module.controlplane_sub.subnets) : subnet if length(regexall("mgmt", lower(subnet))) > 0], 0)
  key_vault_id = data.azurerm_key_vault.this.id
}

resource "azurerm_key_vault_secret" "AZURE_CONTROL_PLANE_SUBNET_NAME_wrk" {
  name         = "AZURE-CONTROL-PLANE-SUBNET-NAME-workload"
  value        = element([for subnet in keys(module.controlplane_sub.subnets) : subnet if length(regexall("work", lower(subnet))) > 0], 0)
  key_vault_id = data.azurerm_key_vault.this.id
}

resource "azurerm_key_vault_secret" "AZURE_NODE_SUBNET_NAME_mgmt" {
  name         = "AZURE-NODE-SUBNET-NAME-management"
  value        = element([for subnet in keys(module.node_sub.subnets) : subnet if length(regexall("mgmt", lower(subnet))) > 0], 0)
  key_vault_id = data.azurerm_key_vault.this.id
}

resource "azurerm_key_vault_secret" "AZURE_NODE_SUBNET_NAME_wrk" {
  name         = "AZURE-NODE-SUBNET-NAME-workload"
  value        = element([for subnet in keys(module.node_sub.subnets) : subnet if length(regexall("work", lower(subnet))) > 0], 0)
  key_vault_id = data.azurerm_key_vault.this.id
}
resource "azurerm_key_vault_secret" "AZURE_FRONTEND_PRIVATE_IP" {
  name         = "AZURE-FRONTEND-PRIVATE-IP"
  value        = cidrhost(local.tkgm_mgmtctrl_net[0], 4)
  key_vault_id = data.azurerm_key_vault.this.id
}

resource "azurerm_key_vault_secret" "AZURE_NODE_SUBNET_CIDR_mgmt" {
  name         = "AZURE-NODE-SUBNET-CIDR-management"
  value        = local.tkgm_mgmtnode_net[0]
  key_vault_id = data.azurerm_key_vault.this.id
}

resource "azurerm_key_vault_secret" "AZURE_NODE_SUBNET_CIDR_wrk" {
  name         = "AZURE-NODE-SUBNET-CIDR-workload"
  value        = local.tkgm_wrknode_net[0]
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

resource "azurerm_key_vault_secret" "CLUSTER_NAME" {
  name         = "CLUSTER-NAME"
  value        = var.tkg_cluster_name
  key_vault_id = data.azurerm_key_vault.this.id
}