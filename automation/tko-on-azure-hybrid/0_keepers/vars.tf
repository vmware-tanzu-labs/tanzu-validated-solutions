/* Global Values */
variable "sub_id" {
  description = "The subscription ID where these resources should be built."
}

variable "tenant_id" {
  description = "The tenant ID (Azure Active Directory) linked to your subscription."
}

variable "prefix" {
  default     = "vmw-use2-keeper"
  description = "The prefix used for all infrastructure objects.  i.e. '<prefix>-vnet' or '<prefix>-web-nsg' "
}

variable "prefix_short" {
  default     = "vmwuse2keep"
  description = "This prefix is an abbreviated version of 'prefix' but designed for lower max character names. The short prefix should be a maximum of 8 chars (alpha-numeric)"
}

variable "location" {
  default     = "East US 2"
  description = "The region/location where these resources will be deployed."
}

variable "additional_tags" {
  default = {
    ServiceName  = "TKGm Reference Architecture"
    OwnerEmail   = "tanzu@vmware.com"
    BusinessUnit = "MAPBU"
    Environment  = "Testing"
  }
}

variable "ipAcl" {
  default     = ""
  description = "The IP ACL to be used for the Storage Account and KeyVault.  If left blank, the local executor's IP address will be used."
}

variable "acl_group" {
  default     = ""
  description = "The Azure Active Directory group to be used for access policies.  If left blank, the local executor's account will be used instead of a group."
}