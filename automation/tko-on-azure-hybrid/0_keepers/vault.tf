resource "azurerm_key_vault_secret" "AZURE_SUBSCRIPTION_ID" {
  name         = "AZURE-SUBSCRIPTION-ID"
  value        = var.sub_id
  key_vault_id = module.akv.key_vault.id
}

resource "azurerm_key_vault_secret" "AZURE_TENANT_ID" {
  name         = "AZURE-TENANT-ID"
  value        = var.tenant_id
  key_vault_id = module.akv.key_vault.id
}

resource "azurerm_key_vault_secret" "AZURE_LOCATION" {
  name         = "AZURE-LOCATION"
  value        = var.location
  key_vault_id = module.akv.key_vault.id
}