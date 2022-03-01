resource "random_id" "this" {
  keepers = {
    rg_id = data.azurerm_resource_group.netsec.id
  }

  byte_length = 2
}

locals {
  prefix_short = replace(var.prefix, "/\\W/", "")
  tagOverride = {
    StartDate = timestamp()
  }
  tags = merge(data.azurerm_resource_group.netsec.tags, var.additional_tags, local.tagOverride)
}

module "bindvm" {
  count  = var.bindvms
  source = "../modules/vm"

  rendered_cloudinit_config = data.cloudinit_config.this.rendered
  bootdiag_endpoint         = data.azurerm_storage_account.bootdiag.primary_blob_endpoint
  prefix                    = var.prefix
  prefix_short              = local.prefix_short
  idx                       = count.index + 1
  tags                      = merge(data.azurerm_resource_group.netsec.tags, var.additional_tags, local.tagOverride)
  netsec_resource_group     = var.netsec_resource_group
  location                  = var.location
  subnet_id                 = data.azurerm_subnet.netsec.id
}


# Create Network Security Group and rule
resource "azurerm_network_security_group" "this" {
  name                = "nsg-${local.prefix_short}${random_id.this.hex}"
  location            = var.location
  resource_group_name = var.netsec_resource_group

  security_rule {
    name                       = "Allow_DNS"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "this" {
  count                     = var.bindvms
  network_interface_id      = module.bindvm[count.index].vnic.id
  network_security_group_id = azurerm_network_security_group.this.id
}