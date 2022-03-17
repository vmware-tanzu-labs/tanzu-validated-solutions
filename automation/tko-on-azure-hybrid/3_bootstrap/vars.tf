variable "sub_id" {
  type        = string
  description = "Azure subscription ID - resources created here."
}

variable "location" {
  type        = string
  description = "Azure regional location (keyword from Azure validated list)"
  default     = "eastus2"
}

variable "additional_tags" {
  type        = map(string)
  description = "A mapping of tags to assign to the resource."
  default = {
    ServiceName  = "TKGm Reference Architecture"
    OwnerEmail   = "tanzu@vmware.com"
    BusinessUnit = "MAPBU"
    Environment  = "Testing"
  }
}

variable "boot_diag_sa_name" {
  default     = ""
  description = "The storage account name to be created for holding boot diag data for firewalls as well as NSG Flow logs."
}

variable "netsec_resource_group" {
  default     = ""
  description = "Resource Group name provided by 1_netsec where the VNET and related resources exist."
}

variable "vnet_name" {
  default     = ""
  description = "The VNET provided by 1_netsec."
}

variable "subnet_name" {
  default     = "TKGM-Admin"
  description = "Subnet name picked from the 1_netsec/user-subnets.tf file. The bootstrap machine should live outside of the workload or controlplane subnets."
}

variable "prefix" {
  default     = "vmw-use2-tkgm"
  description = "The prefix used for all infrastructure objects.  i.e. '<prefix>-vnet' or '<prefix>-web-nsg' "
}

variable "prefix_short" {
  default     = "vmwuse2tkgm"
  description = "This prefix is an abbreviated version of 'prefix' but designed for lower max character names. The short prefix should be a maximum of 8 chars (alpha-numeric)"
}

variable "vault_resource_group_name" {
  default     = ""
  description = "The resource group name for the vault provided by 0_keepers - fed by a state data source if left empty"
}
variable "vault_name" {
  default     = ""
  description = "Azure Key Vault as built by 0_keepers - fed by a state data source if left empty"
}

variable "dns_servers" {
  type    = list(string)
  default = []
}

variable "ipAcl" {
  default     = ""
  description = "The IP ACL to be used for the Storage Account and KeyVault.  If left blank, the local executor's IP address will be used."
}

variable "user" {
  default     = "azureuser"
  description = "Bootstrap VM (Ubuntu Linux) default username"
}

variable "http_proxy" {
  default     = ""
  description = "Proxy settings for bootstrap and TKG cluster members, e.g. http://user:password@myproxy.com:1234"
}

variable "https_proxy" {
  default     = ""
  description = "Proxy settings for bootstrap and TKG cluster members, e.g. http://user:password@myproxy.com:1234"
}

variable "no_proxy" {
  default     = ""
  description = "comma-separated list of hosts, CIDR, or domains to bypass proxy"
}