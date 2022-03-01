output "storage_account" {
  value = azurerm_storage_account.this.name
}

output "access_key" {
  value     = azurerm_storage_account.this.primary_access_key
  sensitive = true
}

output "key_vault" {
  value = module.akv.key_vault.name
}

output "keeper_resource_group_name" {
  value = azurerm_resource_group.this.name
}