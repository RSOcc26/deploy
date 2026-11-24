terraform {
  required_version = ">= 1.10"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.14"
    }
  }

  # State lives in Azure Storage (created once by hand, see README), never in
  # Git: it contains the cluster's credentials. Azure AD auth, no account keys.
  backend "azurerm" {
    resource_group_name  = "rso-rg"
    storage_account_name = "rsocc26tfstate"
    container_name       = "tfstate"
    key                  = "companycentral.tfstate"
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  # The providers we use are registered once by hand (docs/DevOps ch. 3); CI
  # only has rights on the resource group and could not register them anyway
  resource_provider_registrations = "none"
}
