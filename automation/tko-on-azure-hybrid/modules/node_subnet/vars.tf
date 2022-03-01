variable "local_data" {
  # type        = map(string)
  description = "A map containing all of the information required to build a unique spoke."
}

variable "subnet_settings" {
  default     = {}
  description = "A map of subnets to be created. (e.g. {'net1' = '10.0.0.0/24', 'net2' = '10.0.1.0/24'} )"
}

#===================================
#  Flow Logs Variables
#===================================
variable "flow_log_data" {
  type        = map(string)
  description = <<EOF
    This map contains all of the log analytics data needed to set up NSG flow logs.  It contains the following:
    "law_id" -- Log Analytics ID
    "law_workspace_id" -- Log Analytics Workspace ID
    "nw_name" -- Network Watcher Name for this spoke/region
    "nw_rg_name" -- Resource Group Name for the Network Watcher in this spoke/region
    "flow_log_sa_id" -- Boot Diagnostics Storage Account ID (used for both boot diag and nsg flow logs)
EOF
}
