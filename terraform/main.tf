terraform {
  required_version = ">= 1.6.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
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
}


module "Create_App_Service" {
  source = "./modules/Create_App_Service"
}
