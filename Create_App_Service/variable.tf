# variables.tf
variable "resource_group_name" {
  type    = string
  default = "AbelTeraRG"
}

variable "location" {
  type    = string
  default = "West Europe"
}

variable "app_service_plan_name" {
  type    = string
  default = "AbelASP"
}

variable "app_service_name" {
  type    = string
  default = "Abel-Project2232"
}