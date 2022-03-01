#---------------------------------------------
#  TERRAFORM SETUP
#---------------------------------------------

terraform {
  required_version = "~> 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.79"
    }
  }
}

provider "azurerm" {
  subscription_id = var.sub_id

  features {}
}

# provider "azuread" {
#   version         = "= 0.10"
#   subscription_id = var.sub_id
# }

provider "random" {}