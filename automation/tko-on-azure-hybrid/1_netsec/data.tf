data "terraform_remote_state" "keeper" {
  backend = "local"

  config = {
    path = "../0_keepers/terraform.tfstate"
  }
}

data "azurerm_subscription" "this" {
  subscription_id = var.sub_id
}