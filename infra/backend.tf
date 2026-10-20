terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstatepj1234"
    container_name       = "tfstate"
    key                  = "eventapp-dev.tfstate"
    use_azuread_auth     = true
  }
}