# tkg init --config ./tkg-aws.yaml  -i aws -p prod --ceip-participation false --name iz-aws --cni antrea -v 6

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      CreatedBy = "Arcas"
      RunId=var.run_id
    }
  }
  ignore_tags {
    keys = ["kubernetes.io"]
  }
}



variable "aws_region" {
  default = "us-west-2"
}

variable "run_id" {
  default = "none"
}

variable "to_url" {
  default = ""
}

variable "to_token" {
  default = ""
}

variable "jb_key_file" {
  default = "./tkgkp.pem"
}

variable "jb_key_pair" {
  default = "tkg-kp"
}

resource "aws_ec2_transit_gateway" "transitgw" {
  description = "transit gw"
}


module "control_plane" {
  source        = "./tkg_vpc"
  vpc_subnet    = "172.16.0.0/16"
  jumpbox       = true
  transit_gw    = aws_ec2_transit_gateway.transitgw.id
  transit_block = "172.16.0.0/12"
  name          = "control-plane"
  jb_key_pair   = var.jb_key_pair
  jb_keyfile    = var.jb_key_file
  cluster_name  = "tkg-mgmt-aws"
  azs           = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  to_token      = var.to_token
  to_url        = var.to_url
}

module "workload_vpc" {
  source        = "./tkg_vpc"
  vpc_subnet    = "172.18.0.0/16" // avoiding .17 so that we don't conflict with docker
  jumpbox       = false
  transit_gw    = aws_ec2_transit_gateway.transitgw.id
  transit_block = "172.16.0.0/12"
  name          = "workload"
  cluster_name  = "tkg-workload"
  azs           = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
}

output "jumpbox_dns" {
  value = module.control_plane.jumpbox_dns
}
