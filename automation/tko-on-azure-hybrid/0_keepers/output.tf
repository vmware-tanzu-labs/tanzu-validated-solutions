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

output "run_me" {
  value = "~~ set environment ARM_ACCESS_KEY ~~ `terraform output -raw access_key`"
}

# resource "null_resource" "this" {
#   provisioner "local-exec" {
#     command = "$env:ARM_ACCESS_KEY=\"${azurerm_storage_account.this.primary_access_key}\""
#     interpreter = ["pwsh", "-NoProfile", "-Command"]
#   }
# }