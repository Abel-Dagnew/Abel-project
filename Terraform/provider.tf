provider "azuredevops" {
  org_service_url       = "https://dev.azure.com/v-abeldagnew"
  personal_access_token = var.personal_access_token  # This could be defined as a sensitive variable
  alias = "azdevpro"
}