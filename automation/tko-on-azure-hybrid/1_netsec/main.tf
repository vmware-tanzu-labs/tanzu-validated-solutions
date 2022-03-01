#---------------------------------------------
#  RESOURCE GROUP
#---------------------------------------------
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.prefix}"
  location = var.location

  tags = local.tags

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

#---------------------------------------------
#  RESOURCES
#---------------------------------------------
module "vnet_base" {
  source            = "../modules/vnet"
  local_data        = local.base_inputs
  dns_list          = []
  boot_diag_sa_name = var.boot_diag_sa_name
}

module "myip" {
  source  = "4ops/myip/http"
  version = "1.0.0"
}