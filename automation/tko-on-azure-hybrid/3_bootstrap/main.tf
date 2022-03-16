locals {
  tagOverride = {
    StartDate = timestamp()
  }
  tags = merge(data.azurerm_subscription.this.tags, var.additional_tags, local.tagOverride)
}

module "myip" {
  source  = "4ops/myip/http"
  version = "1.0.0"
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${var.prefix}"
  location = var.location

  tags = local.tags

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

# Create public IPs
resource "azurerm_public_ip" "this" {
  name                = "pip-${var.prefix_short}-bootstrap"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Dynamic"

  tags = azurerm_resource_group.this.tags

  lifecycle {
    ignore_changes = [
      tags["StartDate"]
    ]
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "this" {
  name                = "nsg-${var.prefix_short}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name

  security_rule {
    name                       = "Allow_Select_SSH"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = local.ipAcl
    destination_address_prefix = "*"
  }

  tags = azurerm_resource_group.this.tags

  lifecycle {
    ignore_changes = [
      tags["StartDate"],
    ]
  }
}

# Create network interface
resource "azurerm_network_interface" "this" {
  name                = "nic-${var.prefix_short}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  dns_servers         = var.dns_servers # output from 2_dns

  ip_configuration {
    name                          = "ipcfg-${var.prefix_short}"
    subnet_id                     = data.azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }

  tags = azurerm_resource_group.this.tags

  lifecycle {
    ignore_changes = [
      tags["StartDate"],
    ]
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "this" {
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

# Create (and display) an SSH key
resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "null_resource" "az_eula_2004" {
  provisioner "local-exec" {
    command = "az vm image terms accept --publisher vmware-inc --offer tkg-capi --plan k8s-1dot21dot2-ubuntu-2004 --subscription ${var.sub_id}"
  }
}

resource "null_resource" "az_eula_1804" {
  provisioner "local-exec" {
    command = "az vm image terms accept --publisher vmware-inc --offer tkg-capi --plan k8s-1dot21dot2-ubuntu-1804 --subscription ${var.sub_id}"
  }
}

resource "azurerm_virtual_machine_extension" "tkgcli" {
  name                       = "tkg_cli_prereqs"
  virtual_machine_id         = azurerm_linux_virtual_machine.this.id
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "CustomScript"
  type_handler_version       = "2.0"
  auto_upgrade_minor_version = false

  settings = <<SETTINGS
    {
        "script": "${filebase64("${path.module}/bootstrap.sh")}"
    }
SETTINGS
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "this" {
  name                       = "vm-${var.prefix_short}-bootstrap"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.this.name
  network_interface_ids      = [azurerm_network_interface.this.id]
  size                       = "Standard_B2ms"
  allow_extension_operations = true

  os_disk {
    name                 = "os-${var.prefix_short}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    # offer     = "UbuntuServer"
    # sku       = "18.04-LTS"
    offer   = "0001-com-ubuntu-server-focal"
    sku     = "20_04-lts-gen2"
    version = "latest"
  }

  computer_name  = var.prefix_short
  admin_username = var.user
  # admin_password                  = "secret"
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.user
    public_key = tls_private_key.this.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = data.azurerm_storage_account.bootdiag.primary_blob_endpoint
  }

  custom_data = data.cloudinit_config.this.rendered

  tags = azurerm_resource_group.this.tags

  lifecycle {
    ignore_changes = [
      tags["StartDate"],
    ]
  }
}

resource "local_file" "bootstrap_priv_key" {
  filename        = "${path.module}/bootstrap.pem"
  file_permission = "0600"
  content         = tls_private_key.this.private_key_pem
}