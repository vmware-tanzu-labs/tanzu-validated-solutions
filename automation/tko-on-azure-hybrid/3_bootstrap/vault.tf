data "azurerm_key_vault" "this" {
  name                = var.vault_name
  resource_group_name = var.vault_resource_group_name
}

resource "azurerm_key_vault_secret" "AZURE_SSH_PUBLIC_KEY_B64" {
  name         = "AZURE-SSH-PUBLIC-KEY-B64"
  value        = base64encode(tls_private_key.this.public_key_openssh)
  key_vault_id = data.azurerm_key_vault.this.id
}

resource "azurerm_key_vault_secret" "bootstrap_tls_private_key" {
  name         = "bootstrap-tls-private-key"
  value        = tls_private_key.this.private_key_pem
  key_vault_id = data.azurerm_key_vault.this.id
}