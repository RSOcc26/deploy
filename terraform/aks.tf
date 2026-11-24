# The AKS cluster (ADR-0004). Generated from the live cluster with
# `terraform plan -generate-config-out` and reduced to the settings we choose;
# values Azure computes (identities, node resource group contents, CIDR lists)
# are left out so they never show as drift.

resource "azurerm_kubernetes_cluster" "main" {
  name                = "rso-cluster"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "rso-cluster-dns"
  node_resource_group = "MC_rso-rg_rso-cluster_austriaeast"

  # Free tier: no control-plane fee, no uptime SLA (ADR-0004)
  sku_tier     = "Free"
  support_plan = "KubernetesOfficial"

  # Azure applies patch releases (1.36.x) itself, so the version is not pinned
  # here; pinning it would show drift after every automatic patch upgrade.
  automatic_upgrade_channel = "patch"
  node_os_upgrade_channel   = "NodeImage"

  role_based_access_control_enabled = true
  local_account_disabled            = false
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  image_cleaner_enabled             = true
  image_cleaner_interval_hours      = 168

  default_node_pool {
    name            = "agentpool"
    vm_size         = "Standard_DS2_v2"
    os_sku          = "Ubuntu"
    os_disk_size_gb = 128
    os_disk_type    = "Managed"
    max_pods        = 110

    auto_scaling_enabled = true
    min_count            = 2
    max_count            = 5

    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    day_of_week = "Sunday"
    duration    = 8
    start_time  = "00:00"
    utc_offset  = "+00:00"
  }

  maintenance_window_node_os {
    frequency   = "Weekly"
    interval    = 1
    day_of_week = "Sunday"
    duration    = 8
    start_time  = "00:00"
    utc_offset  = "+00:00"
  }

  # Node pools are managed by hand (not Node Auto Provisioning)
  node_provisioning_profile {
    mode = "Manual"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "azure"
    load_balancer_sku   = "standard"
    outbound_type       = "loadBalancer"
    pod_cidr            = "10.244.0.0/16"
    service_cidr        = "10.0.0.0/16"
    dns_service_ip      = "10.0.0.10"
  }

  lifecycle {
    ignore_changes = [
      # The autoscaler changes the node count; Terraform must not reset it
      default_node_pool[0].node_count,
      # Azure leaves this unset in Manual mode; the provider default would only cause a no-op update
      node_provisioning_profile[0].default_node_pools,
    ]
    # Rebuilding the cluster is a deliberate act, never a side effect of a plan
    prevent_destroy = true
  }
}
