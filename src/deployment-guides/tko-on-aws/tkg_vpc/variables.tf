variable "vpc_subnet" {
  default     = "192.168.0.0/16"
  description = "The vpc subnet"
  type        = string
}

variable "azs" {
  default     = ["us-east-2a", "us-east-2b", "us-east-2c"]
  description = "List of VPCs"
  type        = list(string)
}
variable "jumpbox" {
  default     = false
  description = "jumpbox? true/false"
  type        = bool
}
variable "name" {
  default = "nonameset"
}
variable "jb_key_pair" {
  default = "tkg-kp"
}

variable "jb_keyfile" {
  default = "~/tkg-kp.pem"
}

variable "cluster_name" {
  default = "tkg-mgmt-aws-20201112203436"
}

variable "transit_gw" {
}
variable "transit_block" {
}

variable "to_url" {
  default = ""
}

variable "to_token" {
  default = ""
}