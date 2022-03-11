#####################################
# Subscription vars:
#####################################
# sub_id   = ""                     # Azure Subscription ID
# location = "e.g. East US 2"       # Azure region name
# prefix   = "e.g. va-use2-midgard" # Concatenated with resource abbreviations and other elements to produce standardized names

#####################################
# Tags
#####################################
# additional_tags = {
#   ServiceName = "e.g. BIND 9 Forwarder"
#   OwnerEmail  = "e.g. ogradin@vmware.com"
# }

#####################################
# Network vars:
#####################################
# subnet_name           = "e.g. TKGM-Admin"                      # Subnet name taken from the VNET where it is defined
# vnet_name             = "e.g. vnet-va-useast2-poc-tkgm-netsec" # complete VNET name as defined in Azure
# netsec_resource_group = "e.g. rg-va-useast2-poc-tkgm-netsec"   # complete resource group name where the VNET exists
# bindvms               = 2                                      # this is how many DNS VMs you will have in the end

#####################################
# Platform vars:
#####################################
# boot_diag_sa_name = "vause2netsecdiag" # Storage Account name used for Boot Diagnostics - defined in 1_netsec