# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "990eb721-14f5-4a32-9154-c213e7d1ba28"
  tenant_id       = "409f9d07-b590-4145-96ff-50ada9a681dd"
}

# Criação dos Resource Groups
resource "azurerm_resource_group" "terraform_rg" {
  name     = var.resource_group_name_terraform
  location = var.azure_region_eastus
}

resource "azurerm_storage_account" "sto002prod" {
  name                     = var.sa_name
  resource_group_name      = var.resource_group_name_terraform
  location                 = var.azure_region_eastus
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "Tfstate terraform"
  }
}

resource "azurerm_storage_container" "blobcont01" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.sto002prod
  container_access_type = "blob"
}