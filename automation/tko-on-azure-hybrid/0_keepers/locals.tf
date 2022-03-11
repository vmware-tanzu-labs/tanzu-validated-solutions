locals {
  tagOverride = {
    StartDate = timestamp()
  }
  tags = merge(data.azurerm_subscription.this.tags, var.additional_tags, local.tagOverride)

  netsec_prov = templatefile("../1_netsec/provider.tftpl", azurerm_storage_account.this)
  dns_prov = templatefile("../2_dns/provider.tftpl", azurerm_storage_account.this)
  bootstrap_prov = templatefile("../3_bootstrap/provider.tftpl", azurerm_storage_account.this)
  bootstrap_data = templatefile("../3_bootstrap/data.tftpl", azurerm_storage_account.this)

  ipAcl = var.ipAcl != "" ? var.ipAcl : module.myip.address

  acl_obj_id = var.acl_group != "" ? data.azuread_group.this[0].object_id : data.azurerm_client_config.current.object_id
}