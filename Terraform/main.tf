terraform {
  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 0.1"
    }
  }
}



module "Create_Devops_Project" {
  
  source = "./Create_Devops_Project"
  providers = {
    azuredevops = azuredevops.azdevpro
  }
  github_token = var.github_token
   
}









