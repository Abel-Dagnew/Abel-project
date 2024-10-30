terraform {
  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 0.1"
    }
  }
}





module "Create_App_Service" {
  
  source = "./Create_App_Service"
  providers = {
    azurerm = azurerm.azresourceprovider
  }
     
}









