variable "prefix" {}
variable "prefix_short" {}
variable "location" {}
variable "resource_group" {}
variable "tenant_id" {}
variable "random_hex" {}
variable "tags" {}
variable "acl_ip" {}
variable "acl_obj_id" {}

resource "azurerm_key_vault" "this" {
  name                        = "kv-${var.prefix}-${var.random_hex}"
  location                    = var.location
  resource_group_name         = var.resource_group
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags["StartDate"],
    ]
  }

  access_policy {
    tenant_id = var.tenant_id
    object_id = var.acl_obj_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get", "Delete", "List", "Purge", "Recover", "Backup", "Restore", "Set"
    ]

    storage_permissions = [
      "Get",
    ]
  }

  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow" # Currently "allowed" to support access from the VNET later which does not get added here at this early stage
    ip_rules       = [var.acl_ip]
  }
}

output "key_vault" {
  value = azurerm_key_vault.this
}