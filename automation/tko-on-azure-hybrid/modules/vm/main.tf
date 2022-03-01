

resource "azurerm_linux_virtual_machine" "this" {
  name                = "vm-${var.prefix_short}${var.idx}"
  resource_group_name = var.netsec_resource_group
  location            = var.location
  size                = "Standard_B1ms"
  network_interface_ids = [
    azurerm_network_interface.this.id,
  ]

  computer_name                   = "${var.prefix_short}${var.idx}"
  admin_username                  = "azureuser"
  admin_password                  = "ThisIsASecretPassword!"
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = var.bootdiag_endpoint
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags["StartDate"],
    ]
  }

  custom_data = var.rendered_cloudinit_config
}

variable "rendered_cloudinit_config" {}
variable "bootdiag_endpoint" {}
variable "prefix" {}
variable "prefix_short" {}
variable "tags" {}
variable "netsec_resource_group" {}
variable "location" {}
variable "subnet_id" {}
variable "idx" {}

resource "azurerm_network_interface" "this" {
  name                = "nic-${var.prefix_short}${var.idx}"
  location            = var.location
  resource_group_name = var.netsec_resource_group

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

output "vnic" {
  value = azurerm_network_interface.this
}

output "vm" {
  value = azurerm_linux_virtual_machine.this
}