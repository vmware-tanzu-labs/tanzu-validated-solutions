/* Global Values */
variable "sub_id" {
  description = "The subscription ID where these resources should be built."
}

variable "tenant_id" {}

variable "prefix" {
  description = "The prefix used for all infrastructure objects.  i.e. '<prefix>-vnet' or '<prefix>-web-nsg' "
}

variable "prefix_short" {
  description = "This prefix is an abbreviated version of 'prefix' but designed for lower max character names. The short prefix should be a maximum of 8 chars (alpha-numeric)"
}

variable "location" {
  description = "The region/location where these resources will be deployed."
}

variable "additional_tags" {

}