
########### BLOCO DE VARIAVEIS ######
variable "azure_region_eastus" {
  type        = string
  default     = "eastus"
  description = "description"
}

variable "resource_group_name_terraform" {
  type        = string
  default     = "terraform_rg"
  description = "description"
}

variable "sa_name" {
  type        = string
  default     = "stoprod0001tfstate"
  description = "description"

}

variable "container_name" {
  type        = string
  default     = "tfstate"
  description = "description"

}