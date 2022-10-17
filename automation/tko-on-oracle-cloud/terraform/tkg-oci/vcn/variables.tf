variable "label_prefix" {
  description = "Label prefix for all resources"
  type        = string
  default     = "tkg.cloud.vmware.com"
}

variable "vcn_cidr" {
  type        = string
  description = "CIDR block for the VCN"
  default     = "10.0.0.0/20"
}

variable "create_internet_gateway" {
  description = "Allow any connectivity to the internet"
  type        = bool
  default     = true
}

variable "create_nat_gateway" {
  description = "Allow TKG cluster to have internet access"
  type        = bool
  default     = true
}

variable "create_service_gateway" {
  description = "Create a service gateway for the VCN"
  type        = bool
  default     = true
}

variable "public_control_plane_endpoint" {
  description = "Expose Kubernetes control plane endpoint on public internet"
  type        = bool
  default     = false
}

variable "create_public_services_subnet" {
  description = "Create public facing subnet for Kubernetes service load balancers"
  type        = bool
  default     = false
}

variable "nat_gateway_public_ip_id" {
  description = "OCID of reserved IP address for NAT gateway. The reserved public IP address needs to be manually created."
  default     = "none"
  type        = string
}

variable "vcn_name" {
  description = "Name of the VCN that will be created"
  default     = "vcn"
  type        = string
}

# gateways parameters
variable "internet_gateway_display_name" {
  description = "(Updatable) Name of Internet Gateway. Does not have to be unique."
  type        = string
  default     = "internet-gateway"

  validation {
    condition     = length(var.internet_gateway_display_name) > 0
    error_message = "The internet_gateway_display_name value cannot be an empty string."
  }
}

variable "local_peering_gateways" {
  description = "Map of Local Peering Gateways to attach to the VCN."
  type        = map(any)
  default     = null
}

variable "nat_gateway_display_name" {
  description = "(Updatable) Name of NAT Gateway. Does not have to be unique."
  type        = string
  default     = "nat-gateway"

  validation {
    condition     = length(var.nat_gateway_display_name) > 0
    error_message = "The nat_gateway_display_name value cannot be an empty string."
  }
}

variable "service_gateway_display_name" {
  description = "(Updatable) Name of Service Gateway. Does not have to be unique."
  type        = string
  default     = "service-gateway"

  validation {
    condition     = length(var.service_gateway_display_name) > 0
    error_message = "The service_gateway_display_name value cannot be an empty string."
  }
}

variable "internet_gateway_route_rules" {
  description = "(Updatable) List of routing rules to add to Internet Gateway Route Table"
  type        = list(map(string))
  default     = null
}

variable "lockdown_default_seclist" {
  description = "whether to remove all default security rules from the VCN Default Security List"
  default     = true
  type        = bool
}

variable "vcn_dns_label" {
  description = "A DNS label for the VCN, used in conjunction with the VNIC's hostname and subnet's DNS label to form a fully qualified domain name (FQDN) for each VNIC within this subnet"
  type        = string
  default     = "vcnmodule"

  validation {
    condition     = length(regexall("^[^0-9][a-zA-Z0-9_]+$", var.vcn_dns_label)) > 0
    error_message = "DNS label must be an alphanumeric string that begins with a letter."
  }
}

variable "nat_gateway_route_rules" {
  description = "(Updatable) list of routing rules to add to NAT Gateway Route Table"
  type        = list(map(string))
  default     = null
}

variable "attached_drg_id" {
  description = "the ID of DRG attached to the VCN"
  type        = string
  default     = null
}

variable "additional_subnets" {
  description = "Additional subnets to create"
  type        = any
  default     = {}
}

variable "create_bastion_vm" {
  description = "Create a bastion VM in the public services subnet"
  type        = bool
  default     = false
}

variable "create_instance_principals" {
  description = "Create instance principals for the Kubernetes cluster"
  type        = bool
  default     = true
}

// TODO:
// Create LB
