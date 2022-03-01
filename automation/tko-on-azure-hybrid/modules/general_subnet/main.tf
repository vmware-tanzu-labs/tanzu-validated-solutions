#--------------------------------------------
#  SUBNET AND ROUTE CREATION
#--------------------------------------------
resource "azurerm_subnet" "tier_net" {
  for_each = var.subnet_settings

  name                                           = each.key
  address_prefix                                 = each.value.network
  resource_group_name                            = var.local_data.resource_group_name
  virtual_network_name                           = var.local_data.vnet_name
  service_endpoints                              = each.value.service_endpoints
  enforce_private_link_endpoint_network_policies = each.value.allow_plink_endpoints

  lifecycle {
    ignore_changes = [
      delegation,
      # removed service_delegation and service_endpoint
    ]
  }
}

# Example route change for default
# resource "azurerm_route" "tier_TO_internet" {
#   for_each = local.subnets

#   name                   = "Default_Route"
#   resource_group_name    = var.local_data.resource_group_name
#   route_table_name       = azurerm_route_table.tier_rt[each.key].name
#   address_prefix         = "0.0.0.0/0"
#   next_hop_type          = "VirtualAppliance"
#   next_hop_in_ip_address = VALID_TARGET_IP
# }

#      ------------- Route Table Assocation -------------
# resource "azurerm_subnet_route_table_association" "tier" {
#   for_each = local.subnets

#   subnet_id      = azurerm_subnet.tier_net[each.key].id
#   route_table_id = azurerm_route_table.tier_rt[each.key].id
# }


#---------------------------------------------
#  NSG CREATION
#---------------------------------------------
# Example rulesets including defaults
#------------- Subnet NSGs    -------------
resource "azurerm_network_security_group" "tier" {
  for_each = local.subnets

  name                = "nsg-${var.local_data.vnet_name}-${each.key}"
  location            = var.local_data.location
  resource_group_name = var.local_data.resource_group_name

  tags = var.local_data.tags

  lifecycle {
    ignore_changes = [
      tags["StartDate"],
    ]
  }
}

#------------- Subnet NSG Rules -------------
resource "azurerm_network_security_rule" "tier_allow_HealthProbe_in" {
  for_each = local.subnets

  name                        = "Allow_Azure_Healthprobes"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_address_prefix       = "AzureLoadBalancer"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "*"
  resource_group_name         = var.local_data.resource_group_name
  network_security_group_name = azurerm_network_security_group.tier[each.key].name
}

resource "azurerm_network_security_rule" "tier_allow_Select_in" {
  for_each = local.subnets

  name                        = "Allow_Select"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_address_prefix       = var.local_data.myip
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "*"
  resource_group_name         = var.local_data.resource_group_name
  network_security_group_name = azurerm_network_security_group.tier[each.key].name
}

# Block all public IPs from reaching inside except those rules above this one
resource "azurerm_network_security_rule" "tier_block_internet_in" {
  for_each = local.subnets

  name                        = "Block_Internet_In"
  priority                    = 105
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_address_prefix       = "Internet"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "*"
  resource_group_name         = var.local_data.resource_group_name
  network_security_group_name = azurerm_network_security_group.tier[each.key].name
}

# ER is ExpressRoute and represents anything except Internet IPs and anything else already allowed
resource "azurerm_network_security_rule" "tier_allow_er_in" {
  for_each = local.subnets

  name                        = "Allow_ER_Inbound"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_address_prefix       = "*" # could be more specific such as RFC 1918 IPs from on-prem/VNETs
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "*"
  resource_group_name         = var.local_data.resource_group_name
  network_security_group_name = azurerm_network_security_group.tier[each.key].name
}

resource "azurerm_network_security_rule" "tier_allow_all_out" {
  for_each = local.subnets

  name                        = "Allow_All_Outbound"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_address_prefix       = "*"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "*"
  resource_group_name         = var.local_data.resource_group_name
  network_security_group_name = azurerm_network_security_group.tier[each.key].name
}

#------------- NSG Flow Logs -------------
resource "azurerm_network_watcher_flow_log" "tier" {
  for_each = local.subnets

  network_watcher_name      = var.flow_log_data.nw_name
  resource_group_name       = var.flow_log_data.nw_rg_name
  network_security_group_id = azurerm_network_security_group.tier[each.key].id
  storage_account_id        = var.flow_log_data.flow_log_sa_id
  enabled                   = true

  retention_policy {
    enabled = true
    days    = 30
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = var.flow_log_data.law_workspace_id
    workspace_region      = var.local_data.location
    workspace_resource_id = var.flow_log_data.law_id
  }

  tags = var.local_data.tags

  lifecycle {
    ignore_changes = [
      tags["StartDate"],
    ]
  }
}

#      ------------- NSG Assocation (all others) -------------
resource "azurerm_subnet_network_security_group_association" "tier" {
  for_each = local.subnets

  subnet_id                 = azurerm_subnet.tier_net[each.key].id
  network_security_group_id = azurerm_network_security_group.tier[each.key].id
}