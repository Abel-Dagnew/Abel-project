# provider.tf
provider "azurerm" {
  features {}
  alias           = "azresourceprovider"
  client_id       = var.client_id       // Reference a variable
  client_secret   = var.client_secret   // Reference a variable
  tenant_id       = var.tenant_id       // Reference a variable
  subscription_id = var.subscription_id  // Reference a variable
}
