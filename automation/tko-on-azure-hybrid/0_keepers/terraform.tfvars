#####################################
# Subscription vars:
#####################################
# sub_id       = ""                     # Azure Subscription ID
# tenant_id    = ""                     # Azure (Active Directory) Tenant ID - needed for KeyVault role permissions
# location     = "e.g. East US 2"       # Azure region name
# prefix       = "e.g. va-use2-keepers" # Concatenated with resource abbreviations and other elements to produce standardized names
# prefix_short = "e.g. vause2keep"      # Shortened and simplified version of above - needed for certain names like Storage Accounts
# ipAcl        = ""                     # IPv4 CIDR to allow access to Storage Account and Key Vault
# acl_group    = ""                     # Azure AD group name for access policies

#####################################
# TKG Vars
#####################################
# additional_tags = {
#   ServiceName  = "e.g. Valhalla TKGm PoC"
#   BusinessUnit = "e.g. Aesir"
#   Environment  = "e.g. Midgard"
#   OwnerEmail   = "e.g. ogradin@vmware.com"
# }