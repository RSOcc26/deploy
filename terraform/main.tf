# CompanyCentral infrastructure on Azure (ADR-0004).
# The resource group and cluster were first created by hand in the portal and
# are adopted with the import blocks below; nothing is recreated.

resource "azurerm_resource_group" "main" {
  name     = "rso-rg"
  location = "austriaeast"

  lifecycle {
    # Also holds the Terraform state storage account
    prevent_destroy = true
  }
}

import {
  to = azurerm_resource_group.main
  id = "/subscriptions/${var.subscription_id}/resourceGroups/rso-rg"
}

import {
  to = azurerm_kubernetes_cluster.main
  id = "/subscriptions/${var.subscription_id}/resourceGroups/rso-rg/providers/Microsoft.ContainerService/managedClusters/rso-cluster"
}
