locals {
  tagOverride = {
    StartDate = timestamp()
  }
  tags = merge(data.azurerm_subscription.this.tags, var.additional_tags, local.tagOverride)
}

#--------------------------------------
#  CONSOLIDATED INFO ABOUT THIS VNET
#--------------------------------------
locals {
  # Consolidated list of inputs required by the base module (i.e. spoke_base, hub_base)
  base_inputs = {
    prefix              = var.prefix
    sub_id              = var.sub_id
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location
    core_address_space  = var.core_address_space
    myip                = module.myip.address
    tags                = local.tags
    tkg_cluster_name    = var.tkg_cluster_name
  }

  # List of all outputs that come from the base module that will be referenced elsewhere.
  base_outputs = {
    vnet_name = module.vnet_base.vnet_name
    vnet_id   = module.vnet_base.vnet_id
  }

  # Merged list of all inputs and outputs for the base module.  This data will be used by other repos (sec) and modules (network_tier)
  local_data = merge(local.base_inputs, local.base_outputs)
}