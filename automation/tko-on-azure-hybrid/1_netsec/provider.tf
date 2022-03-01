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

  backend "azurerm" {
    storage_account_name = "" # Azure Storage Account name created in 0_keepers (or otherwise provided) - must be in the subscription 
    container_name       = "terraform-state"
    key                  = "i.e. [bu or org]/[product]/[location]-[environment]-[TF config purpose].tfstate" # e.g. aesir/tkgm/use2-midgard-net.tfstate

    # access_key = "" Pass via cmd line or environment vars (ARM_ACCESS_KEY)
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