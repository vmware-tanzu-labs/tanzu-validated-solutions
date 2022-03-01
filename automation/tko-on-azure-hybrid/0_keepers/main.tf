module "myip" {
  source  = "4ops/myip/http"
  version = "1.0.0"
}

#---------------------------------------------
#  RESOURCE GROUP
#---------------------------------------------
resource "azurerm_resource_group" "this" {
  name     = "rg-${var.prefix}"
  location = var.location

  tags = local.tags

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

module "akv" {
  source = "../modules/akv"

  prefix         = var.prefix
  prefix_short   = var.prefix_short
  location       = var.location
  resource_group = azurerm_resource_group.this.name
  tenant_id      = var.tenant_id
  random_hex     = random_id.this.hex
  tags           = local.tags
  acl_ip         = module.myip.address
}

resource "random_id" "this" {
  keepers = {
    sa_id = azurerm_resource_group.this.id
  }
  byte_length = 2
}

resource "azurerm_storage_account" "this" {
  name                      = "sa${var.prefix_short}${random_id.this.hex}"
  resource_group_name       = azurerm_resource_group.this.name
  location                  = var.location
  account_kind              = "StorageV2"
  account_tier              = "Standard"
  account_replication_type  = "ZRS"
  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"
  allow_blob_public_access  = false
  # account_encryption_source = "Microsoft.KeyVault"

  # TODO: Requires Service Endpoint Microsoft.Storage on Infra subnet
  network_rules {
    default_action = "Deny"
    bypass         = ["Logging", "Metrics", "AzureServices"]
    # virtual_network_subnet_ids = [data.azurerm_subnet.infra.id]
    # VNETs don't exist yet, so chicken and egg problem
    ip_rules = [module.myip.address]
  }

  tags = azurerm_resource_group.this.tags

  lifecycle {
    ignore_changes = [
      tags["StartDate"],
    ]
  }
}

resource "azurerm_storage_container" "this" {
  name                  = "terraform-state"
  depends_on            = [azurerm_storage_account.this]
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}