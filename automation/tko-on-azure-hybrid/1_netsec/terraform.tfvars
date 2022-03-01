#####################################
# Subscription vars:
#####################################
sub_id                    = ""                                # Azure Subscription ID
location                  = "e.g. East US 2"                  # Azure region name
prefix                    = "e.g. va-useast2-poc-tkgm-netsec" # Concatenated with resource abbreviations and other elements to produce standardized names - must be unique
prefix_short              = "e.g. vause2s"                    # Shortened and simplified version of above - needed for certain names like Storage Accounts
vault_resource_group_name = "e.g. rg-va-use2-keepers"         # this should be the keeper's Resource Group where the AKV lives
vault_name                = "e.g. kv-va-use2-keepers-7ddb"    # our named vault from the output of 0_keepers

#####################################
# TKG Vars
#####################################
additional_tags = {
  ServiceName  = "e.g. Valhalla TKGm PoC"
  BusinessUnit = "e.g. Aesir"
  Environment  = "e.g. Midgard"
  OwnerEmail   = "e.g. ogradin@vmware.com"
}
tkg_cluster_name = "e.g. va-use2-tkgm14-poc" # used as an output to the Vault for variable substitution in the cluster configuration file

#####################################
# Network vars:
#####################################
core_address_space = "e.g. 10.0.0.0/24" # VNET address space allocation - the largest unit to be subdivded by subnets

#####################################
# Platform vars:
#####################################
boot_diag_sa_name = "e.g. vause2netsecdiag" # defines the name of the storage account used for boot diagnostics hereon out. Should probably move this into the keepers