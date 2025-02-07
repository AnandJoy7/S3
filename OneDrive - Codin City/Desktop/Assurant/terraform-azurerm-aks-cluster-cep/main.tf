resource "azurerm_user_assigned_identity" "user_mi" {
  resource_group_name = var.rg_name
  location            = var.location
  tags                = var.tags

  name = "mi-${var.aks_cluster.cluster_name}"
}

resource "azurerm_kubernetes_cluster" "cluster" {
  depends_on = [
    azurerm_role_assignment.udr_role
  ]

  name                = "aks-${var.aks_cluster.cluster_name}"
  location            = var.location
  resource_group_name = var.rg_name

  kubernetes_version = var.aks_cluster.kubernetes_version
  # Per design, private_cluster must be enabled
  private_cluster_enabled             = true
  private_dns_zone_id                 = "None"
  private_cluster_public_fqdn_enabled = true
  # Per design, only standard tier is allowed
  sku_tier = "Standard"

  local_account_disabled = var.aks_cluster.local_account_disabled


  automatic_upgrade_channel = var.aks_cluster.automatic_channel_upgrade
  dns_prefix                = "aks${var.aks_cluster.cluster_name}"

  default_node_pool {
    name                         = var.default_node_pool.name
    node_count                   = var.default_node_pool.node_count
    vm_size                      = var.default_node_pool.vm_size
    type                         = var.default_node_pool.vm_type
    os_disk_size_gb              = var.default_node_pool.os_disk_size_gb
    vnet_subnet_id               = var.default_node_pool.subnet_id
    pod_subnet_id                = var.default_node_pool.pod_subnet_id
    zones                        = var.aks_cluster.zones
    auto_scaling_enabled         = var.default_node_pool.enable_autoscaling
    max_count                    = var.default_node_pool.enable_autoscaling ? var.default_node_pool.autoscaling_max_nodes : null
    min_count                    = var.default_node_pool.enable_autoscaling ? var.default_node_pool.autoscaling_min_nodes : null
    max_pods                     = var.default_node_pool.max_pods
    node_public_ip_enabled       = false
    only_critical_addons_enabled = true

    node_labels = var.default_node_pool.kube_node_labels

    # needed when updating the above parameters
    temporary_name_for_rotation = var.default_node_pool.temporary_name_for_rotation
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.user_mi.id]
  }

  azure_policy_enabled = true

  # maintenance_window
  dynamic "maintenance_window" {
    for_each = var.maintenance_window != null ? [var.maintenance_window] : []

    content {
      dynamic "allowed" {
        for_each = length(maintenance_window.value.allowed) > 0 ? maintenance_window.value.allowed : []

        content {
          day   = allowed.value.day
          hours = allowed.value.hours
        }
      }

      dynamic "not_allowed" {
        for_each = length(maintenance_window.value.not_allowed) > 0 ? maintenance_window.value.not_allowed : []

        content {
          start = not_allowed.value.start
          end   = not_allowed.value.end
        }
      }
    }
  }

  # "maintenance_window_auto_upgrade" 
  dynamic "maintenance_window_auto_upgrade" {
    for_each = var.maintenance_window_auto_upgrade != null ? [var.maintenance_window_auto_upgrade] : []

    content {
      frequency    = maintenance_window_auto_upgrade.value.frequency
      interval     = maintenance_window_auto_upgrade.value.interval
      duration     = maintenance_window_auto_upgrade.value.duration
      day_of_week  = maintenance_window_auto_upgrade.value.day_of_week
      day_of_month = maintenance_window_auto_upgrade.value.day_of_month
      week_index   = maintenance_window_auto_upgrade.value.week_index
      start_time   = maintenance_window_auto_upgrade.value.start_time
      utc_offset   = maintenance_window_auto_upgrade.value.utc_offset
      start_date   = maintenance_window_auto_upgrade.value.start_date

      dynamic "not_allowed" {
        for_each = maintenance_window_auto_upgrade.value.not_allowed != null ? maintenance_window_auto_upgrade.value.not_allowed : []

        content {
          start = not_allowed.value.start
          end   = not_allowed.value.end
        }
      }
    }
  }

  #maintenance_window_node_os
  dynamic "maintenance_window_node_os" {
    for_each = var.maintenance_window_node_os != null ? [var.maintenance_window_node_os] : []

    content {
      frequency    = maintenance_window_node_os.value.frequency
      interval     = maintenance_window_node_os.value.interval
      duration     = maintenance_window_node_os.value.duration
      day_of_week  = maintenance_window_node_os.value.day_of_week
      day_of_month = maintenance_window_node_os.value.day_of_month
      week_index   = maintenance_window_node_os.value.week_index
      start_time   = maintenance_window_node_os.value.start_time
      utc_offset   = maintenance_window_node_os.value.utc_offset
      start_date   = maintenance_window_node_os.value.start_date

      dynamic "not_allowed" {
        for_each = maintenance_window_node_os.value.not_allowed != null ? maintenance_window_node_os.value.not_allowed : []

        content {
          start = not_allowed.value.start
          end   = not_allowed.value.end
        }
      }
    }
  }

  #node_os_upgrade_channel
  dynamic "node_os_upgrade_channel" {
    for_each = var.node_os_channel_upgrade != null ? [var.node_os_channel_upgrade] : []

    content {
      upgrade_channel = node_os_upgrade_channel.value
    }
  }


  dynamic "ingress_application_gateway" {
    for_each = var.network_settings.appgw_subnet_id != "" ? [0] : []
    content {
      subnet_id  = var.network_settings.appgw_subnet_id != "" ? var.network_settings.appgw_subnet_id : null
      gateway_id = var.network_settings.application_gateway_id != "" ? var.network_settings.application_gateway_id : null
    }
  }

  dynamic "key_vault_secrets_provider" {
    for_each = var.key_vault_secrets_provider_enabled ? ["key_vault_secrets_provider"] : []

    content {
      secret_rotation_enabled  = var.key_vault_secrets_provider.secret_rotation_enabled
      secret_rotation_interval = var.key_vault_secrets_provider.secret_rotation_interval
    }
  }

  dynamic "auto_scaler_profile" {
    for_each = var.auto_scaler_profile_enabled ? ["auto_scaler_profile"] : []


    content {
      balance_similar_node_groups      = var.auto_scaler_profile.balance_similar_node_groups
      empty_bulk_delete_max            = var.auto_scaler_profile.empty_bulk_delete_max
      expander                         = var.auto_scaler_profile.expander
      max_graceful_termination_sec     = var.auto_scaler_profile.max_graceful_termination_sec
      max_node_provisioning_time       = var.auto_scaler_profile.max_node_provisioning_time
      max_unready_nodes                = var.auto_scaler_profile.max_unready_nodes
      max_unready_percentage           = var.auto_scaler_profile.max_unready_percentage
      new_pod_scale_up_delay           = var.auto_scaler_profile.new_pod_scale_up_delay
      scale_down_delay_after_add       = var.auto_scaler_profile.scale_down_delay_after_add
      scale_down_delay_after_delete    = local.auto_scaler_profile.scale_down_delay_after_delete
      scale_down_delay_after_failure   = var.auto_scaler_profile.scale_down_delay_after_failure
      scale_down_unneeded              = var.auto_scaler_profile.scale_down_unneeded
      scale_down_unready               = var.auto_scaler_profile.scale_down_unready
      scale_down_utilization_threshold = var.auto_scaler_profile.scale_down_utilization_threshold
      scan_interval                    = var.auto_scaler_profile.scan_interval
      skip_nodes_with_local_storage    = var.auto_scaler_profile.skip_nodes_with_local_storage
      skip_nodes_with_system_pods      = var.auto_scaler_profile.skip_nodes_with_system_pods
    }
  }

  dynamic "workload_autoscaler_profile" {
    for_each = var.workload_autoscaler_profile_enabled ? ["workload_autoscaler_profile"] : []

    content {
      keda_enabled                    = var.workload_autoscaler_profile.keda_enabled
      vertical_pod_autoscaler_enabled = var.workload_autoscaler_profile.vertical_pod_autoscaler_enabled
    }
  }

  network_profile {
    network_plugin = lower(var.network_settings.network_plugin)
    network_policy = lower(var.network_settings.network_plugin) == "azure" ? "azure" : "calico"
    dns_service_ip = var.network_settings.dns_service_ip
    pod_cidr       = lower(var.network_settings.network_plugin) == "kubenet" ? var.network_settings.pod_cidr : null
    service_cidr   = var.network_settings.service_cidr
  }

  role_based_access_control_enabled = true

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = true
    admin_group_object_ids = concat(var.rbac_aad_admin_group_object_ids)
  }



  tags = local.tags
}

