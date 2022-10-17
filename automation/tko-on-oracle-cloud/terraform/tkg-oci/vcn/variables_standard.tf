variable "compartment_id" {
  description = "OCID for the compartment to use"
  type        = string
}


variable "region" {
  description = "Region to use to create the resources"
  type        = string
}

variable "defined_tags" {
  description = "Defined tags to apply to the resources"
  type        = map(string)
  default     = {}
}

variable "freeform_tags" {
  description = "Defined tags to apply to the resources"
  type        = map(string)
  default     = {}
}

variable "enable_tanzu_freeform_tags" {
  description = "Enable tanzu freeform tags"
  type        = bool
  default     = true
}

variable "ignore_defined_tags" {
  description = "Ignore defined tags"
  type        = list(string)
  default     = ["Oracle-Tags.CreatedBy", "Oracle-Tags.CreatedOn", "Owner.Creator"]
}
