terraform {

  required_version = ">= 1.6.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"   # specify your desired version
    }
  }

  
  backend "azurerm" {
    resource_group_name  = "abel_RG"
    storage_account_name = "terraform443"
    container_name       = "terraform-statefile"
    key                  = "terraform.tfstate"
  }
}


provider "azurerm" {
  features {}
  alias           = "azresourceprovider"
   // Reference a variable
   
  use_msi = true
}



module "Create_App_Service" {
  
  source = "./modules/Create_App_Service"
  # providers = {
  #   azurerm = azurerm.azresourceprovider
  # }
     
}








