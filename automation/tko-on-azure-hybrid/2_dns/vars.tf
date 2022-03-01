variable "sub_id" {
  type        = string
  description = "Azure subscription ID - resources created here."
  default     = ""
}

variable "location" {
  type        = string
  description = "Azure regional location (keyword from Azure validated list)"
  default     = "useast2"
}

variable "additional_tags" {
  type        = map(string)
  description = "A mapping of tags to assign to the resource."
  default     = {}
}

variable "boot_diag_sa_name" {

}

variable "netsec_resource_group" {

}

variable "vnet_name" {

}

variable "subnet_name" {

}

variable "prefix" {

}

variable "bindvms" {

}