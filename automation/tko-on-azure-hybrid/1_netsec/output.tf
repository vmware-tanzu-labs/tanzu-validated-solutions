#---------------------------------------------
#   VNET INFORMATION
#---------------------------------------------

output "AZURE_CONTROL_PLANE_SUBNET_CIDR" {
  value = local.tkgm_mgmtctrl_net[0]
}

output "AZURE_CONTROL_PLANE_SUBNET_NAME" {
  # This value is regex matched with 1_netsec/user-subnets.tf to find the target cluster's 'controller' subnet.
  value = element([for subnet in keys(module.controlplane_sub.subnets) : subnet if length(regexall("mgmt", lower(subnet))) > 0], 0)
}

output "AZURE_NODE_SUBNET_NAME" {
  # This value is regex matched with 1_netsec/user-subnets.tf to find the target cluster's 'node' subnet.
  value = element([for subnet in keys(module.node_sub.subnets) : subnet if length(regexall("mgmt", lower(subnet))) > 0], 0)
}

output "AZURE_LOCATION" {
  description = "Region where these resources are deployed."
  value       = azurerm_resource_group.rg.location
}

output "AZURE_FRONTEND_PRIVATE_IP" {
  value = cidrhost(local.tkgm_mgmtctrl_net[0], 4)
}

output "AZURE_NODE_SUBNET_CIDR" {
  value = local.tkgm_mgmtnode_net[0]
}

output "AZURE_SUBSCRIPTION_ID" {
  value = var.sub_id
}

output "AZURE_TENANT_ID" {
  value = data.azurerm_subscription.this.tenant_id
}

output "AZURE_VNET_CIDR" {
  value = var.core_address_space
}

output "AZURE_VNET_NAME" {
  value = module.vnet_base.vnet_name
}

output "AZURE_VNET_RESOURCE_GROUP" {
  value = azurerm_resource_group.rg.name
}

output "CLUSTER_NAME" {
  value = var.tkg_cluster_name
}

output "boot_diag_sa_name" {
  value = var.boot_diag_sa_name
}