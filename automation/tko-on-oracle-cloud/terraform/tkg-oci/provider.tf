terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}

provider "oci" {
  region              = var.region
  ignore_defined_tags = var.ignore_defined_tags
}


provider "oci" {
  alias               = "home"
  region              = var.home_region
  ignore_defined_tags = var.ignore_defined_tags
}
