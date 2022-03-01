data "cloudinit_config" "this" {
  gzip          = false
  base64_encode = true

  part {
    content_type = "cloud-config"
    content      = file("./cloud.yaml")
    filename     = "cloud.yaml"
  }
}

data "azurerm_resource_group" "netsec" {
  name = var.netsec_resource_group
}

data "azurerm_virtual_network" "netsec" {
  name                = var.vnet_name
  resource_group_name = var.netsec_resource_group
}

data "azurerm_subnet" "netsec" {
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.netsec_resource_group
}

data "azurerm_storage_account" "bootdiag" {
  name                = var.boot_diag_sa_name
  resource_group_name = var.netsec_resource_group
}