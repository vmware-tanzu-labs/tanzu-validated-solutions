# Outputs provided for convenience. Source of record should be considered the Azure Key Vault secret store provisioned by 0_keepers!
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

# Bootstrap Public IP can be presented in output if public IPs are used
output "ssh_pip_cmd" {
  value = "ssh -i ${local_file.bootstrap_priv_key.filename} ${var.user}@${azurerm_linux_virtual_machine.this.public_ip_address}"
}

# Bootstrap Private IP can be presented in output if private IPs are used
output "ssh_priv_cmd" {
  value = "ssh -i ${local_file.bootstrap_priv_key.filename} ${var.user}@${azurerm_linux_virtual_machine.this.private_ip_address}"
}