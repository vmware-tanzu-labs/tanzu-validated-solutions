#---------------------------------------------
#  TERRAFORM SETUP
#---------------------------------------------

terraform {
  required_version = "~> 1.1"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 2.98"
    }
    random = {
      version = "~> 3.1.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "= 2.1.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "= 3.1.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "= 2.18.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.sub_id

  features {}
}

provider "azuread" {
  tenant_id = var.tenant_id
}

provider "random" {}

module "myip" {
  source  = "4ops/myip/http"
  version = "1.0.0"
}