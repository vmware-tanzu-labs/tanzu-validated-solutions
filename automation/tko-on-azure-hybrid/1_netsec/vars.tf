/* Global Values */
variable "sub_id" {
  description = "The subscription ID where these resources should be built."
}

variable "prefix" {
  description = "The prefix used for all infrastructure objects.  i.e. '<prefix>-vnet' or '<prefix>-web-nsg' "
}

variable "prefix_short" {
  description = "This prefix is an abbreviated version of 'prefix' but designed for lower max character names. The short prefix should be a maximum of 8 chars (alpha-numeric)"
}

variable "location" {
  description = "The region/location where these resources will be deployed."
}

/* VNet settings */

variable "core_address_space" {
  description = "Transit subnet range.  Range for small subnets used transit networks (generally to FWs)"
}

variable "boot_diag_sa_name" {
  description = "The storage account name to be created for holding boot diag data for firewalls as well as NSG Flow logs."
}

variable "additional_tags" {

}

variable "tkg_cluster_name" {

}

variable "vault_resource_group_name" {}
variable "vault_name" {

}