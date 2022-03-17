locals {
  vault_name                = var.vault_name != "" ? var.vault_name : data.terraform_remote_state.keeper.outputs.key_vault
  vault_resource_group_name = var.vault_resource_group_name != "" ? var.vault_resource_group_name : data.terraform_remote_state.keeper.outputs.keeper_resource_group_name
  netsec_resource_group     = var.netsec_resource_group != "" ? var.netsec_resource_group : data.terraform_remote_state.netsec.outputs.AZURE_VNET_RESOURCE_GROUP
  netsec_vnet               = var.vnet_name != "" ? var.vnet_name : data.terraform_remote_state.netsec.outputs.AZURE_VNET_NAME
  boot_diag_sa_name         = var.boot_diag_sa_name != "" ? var.boot_diag_sa_name : data.terraform_remote_state.netsec.outputs.boot_diag_sa_name

  ipAcl = var.ipAcl != "" ? var.ipAcl : module.myip.address

  cloud_init = {
    "location"    = var.location
    "user"        = var.user
    "http_proxy"  = var.http_proxy
    "https_proxy" = var.https_proxy
    "no_proxy"    = var.no_proxy
  }

  cluster_types = [
    "management",
    "workload"
  ] # Remove "workload" if there are no subnets configured for this additional cluster

  cloud_yaml = {
    # "AZURE-CLIENT-ID"                            = data.azurerm_key_vault_secret.this["AZURE-CLIENT-ID"].value
    # "AZURE-CLIENT-SECRET"                        = data.azurerm_key_vault_secret.this["AZURE-CLIENT-SECRET"].value
    "AZURE-CLIENT-ID"                            = "..."
    "AZURE-CLIENT-SECRET"                        = "..."
    "AZURE-CONTROL-PLANE-SUBNET-CIDR-management" = data.azurerm_key_vault_secret.this["AZURE-CONTROL-PLANE-SUBNET-CIDR-management"].value
    "AZURE-CONTROL-PLANE-SUBNET-CIDR-workload"   = data.azurerm_key_vault_secret.this["AZURE-CONTROL-PLANE-SUBNET-CIDR-workload"].value
    "AZURE-CONTROL-PLANE-SUBNET-NAME-management" = data.azurerm_key_vault_secret.this["AZURE-CONTROL-PLANE-SUBNET-NAME-management"].value
    "AZURE-CONTROL-PLANE-SUBNET-NAME-workload"   = data.azurerm_key_vault_secret.this["AZURE-CONTROL-PLANE-SUBNET-NAME-workload"].value
    "AZURE-FRONTEND-PRIVATE-IP"                  = data.azurerm_key_vault_secret.this["AZURE-FRONTEND-PRIVATE-IP"].value
    "AZURE-LOCATION"                             = data.azurerm_key_vault_secret.this["AZURE-LOCATION"].value
    "AZURE-NODE-SUBNET-CIDR-management"          = data.azurerm_key_vault_secret.this["AZURE-NODE-SUBNET-CIDR-management"].value
    "AZURE-NODE-SUBNET-CIDR-workload"            = data.azurerm_key_vault_secret.this["AZURE-NODE-SUBNET-CIDR-workload"].value
    "AZURE-NODE-SUBNET-NAME-management"          = data.azurerm_key_vault_secret.this["AZURE-NODE-SUBNET-NAME-management"].value
    "AZURE-NODE-SUBNET-NAME-workload"            = data.azurerm_key_vault_secret.this["AZURE-NODE-SUBNET-NAME-workload"].value
    "AZURE-RESOURCE-GROUP"                       = azurerm_resource_group.this.name
    "AZURE-SSH-PUBLIC-KEY-B64"                   = base64encode(tls_private_key.this.public_key_openssh)
    "AZURE-SUBSCRIPTION-ID"                      = data.azurerm_key_vault_secret.this["AZURE-SUBSCRIPTION-ID"].value
    "AZURE-TENANT-ID"                            = data.azurerm_key_vault_secret.this["AZURE-TENANT-ID"].value
    "AZURE-VNET-CIDR"                            = data.azurerm_key_vault_secret.this["AZURE-VNET-CIDR"].value
    "AZURE-VNET-NAME"                            = data.azurerm_key_vault_secret.this["AZURE-VNET-NAME"].value
    "AZURE-VNET-RESOURCE-GROUP"                  = data.azurerm_key_vault_secret.this["AZURE-VNET-RESOURCE-GROUP"].value
    "CLUSTER-NAME"                               = data.azurerm_key_vault_secret.this["CLUSTER-NAME"].value
    "TKG-HTTP-PROXY-ENABLED"                     = var.http_proxy != "" ? "true" : "false"
    "TKG-HTTP-PROXY"                             = var.http_proxy
    "TKG-HTTPS-PROXY"                            = var.https_proxy
    "TKG-NO-PROXY"                               = "${data.azurerm_virtual_network.this.address_space[0]}, capz.io, ${var.no_proxy}"
  }
}