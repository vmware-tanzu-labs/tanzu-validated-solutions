variable "local_data" {
  # type        = map(string)
  default     = {}
  description = "A map containing all of the information required to build a unique spoke."
}

variable "dns_list" {
  type        = list(any)
  default     = []
  description = "A list of DNS servers that the VNet should forward DNS towards"
}

#  Boot Diagnostics Storage Account Name
variable "boot_diag_sa_name" {
  type        = string
  description = "The name assigned to the boot diag storage account."
}