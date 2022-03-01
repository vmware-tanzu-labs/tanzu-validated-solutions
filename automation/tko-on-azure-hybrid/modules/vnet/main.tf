#---------------------------------------------
#   VNET
#---------------------------------------------
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.local_data.prefix}"
  address_space       = [var.local_data.core_address_space]
  location            = var.local_data.location
  resource_group_name = var.local_data.resource_group_name
  dns_servers         = var.dns_list

  tags = var.local_data.tags

  lifecycle {
    ignore_changes = [
      tags["StartDate"],
    ]
  }
}