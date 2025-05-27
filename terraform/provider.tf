# provider.tf
provider "azurerm" {
  features {}
  alias           = "azresourceprovider"
   // Reference a variable
   
  use_cli = true
}
