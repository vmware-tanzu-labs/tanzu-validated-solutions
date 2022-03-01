output "bootstrap_vm" {
  value = azurerm_public_ip.this.ip_address
}

output "bootstrap_usr" {
  value = azurerm_linux_virtual_machine.this.admin_username
}

output "tls_private_key" {
  value     = tls_private_key.this.private_key_pem
  sensitive = true
}

output "AZURE_SSH_PUBLIC_KEY_B64" {
  value = base64encode(tls_private_key.this.public_key_openssh)
}

output "AZURE_RESOURCE_GROUP" {
  value = azurerm_resource_group.this.name
}