terraform {
  
  backend "azurerm" {
    resource_group_name  = "abel_RG"
    storage_account_name = "terraform443"
    container_name       = "terraform-statefile"
    key                  = "terraform.tfstate"
  }
}






module "Create_App_Service" {
  
  source = "./Create_App_Service"
  providers = {
    azurerm = azurerm.azresourceprovider
  }
     
}








