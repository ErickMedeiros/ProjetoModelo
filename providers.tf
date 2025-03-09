# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "tfstateRG01"
    storage_account_name = "tfstate01673324229"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
}
  }