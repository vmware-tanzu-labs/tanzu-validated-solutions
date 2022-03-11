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
  default     = "vmwuse2netsecdiag"
  description = "The storage account name to be created for holding boot diag data for firewalls as well as NSG Flow logs."
}

variable "netsec_resource_group" {
  default     = "rg-vmw-use2-netsec"
  description = "Value defined from 1_netsec"
}

variable "vnet_name" {
  default     = "vnet-vmw-use2-netsec"
  description = "Value defined from 1_netsec"
}

variable "subnet_name" {
  default     = "TKGM-Admin"
  description = "Value defined from 1_netsec (user-subnets)"
}

variable "prefix" {
  default     = "vmw-use2-dnsfwd"
  description = "The prefix used for all infrastructure objects.  i.e. '<prefix>-vnet' or '<prefix>-web-nsg' "
}

variable "bindvms" {
  default     = 2
  description = "A number of VMs to create which host Bind for DNS forwarding to Azure."
}