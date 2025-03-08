########### BLOCO DE VARIAVEIS ######
variable "azure_region" {
 type = string
 default = "eastus" 
 description = "description"
}

variable "resource_group_name" {
  type = string
  default = "eastus-rg"
  description = "description"
}
