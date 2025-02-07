provider "azurerm" {
  features {}
}

variable "TERRATEST_UNIQUE_ID" {
  description = "Terratest Unique ID"
  type        = string
}

module "metadata" {
  source = "app.terraform.io/AIZ/metadata/terratest"

  tags = {
    App_Name = "Terratest"
    App_Env  = var.TERRATEST_UNIQUE_ID
  }
}

locals {
  location = module.metadata.location
  tags     = module.metadata.default_tags
  my_ip    = module.metadata.my_ip

  nodes_subnet_id = "/subscriptions/3c51cc28-d5df-44bb-b15c-cfdd64fff599/resourceGroups/RGSPOKE-CENTRALUS-VDC-SERVICES-MODEL/providers/Microsoft.Network/virtualNetworks/vnet-centralus-vdc-services-model/subnets/ephemeral-aks"
}

module "rg" {
  source = "app.terraform.io/AIZ/resourcegroup-cep/azurerm"

  app_env       = local.tags["App_Env"]
  app_name      = local.tags["App_Name"]
  location      = module.metadata.location
  create_groups = true # Default is true, see notes
  assign_roles  = true # Default is true, see notes

  tags = local.tags
}

module "la" {
  source = "app.terraform.io/AIZ/log-analytics-cep/azurerm"

  rg_name           = module.rg.name
  aw_name           = local.tags["App_Name"]
  location          = module.metadata.location
  sku               = "PerGB2018"
  la_data_retention = 30

  las_plan_details = [{
    las_name  = "ContainerInsights"
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }]

  tags = local.tags
}

module "aks-cep" { 
  source = "../"

  aks_cluster = {
    cluster_name               = local.tags["App_Env"]
    automatic_channel_upgrade  = "patch"
    node_os_channel_upgrade    = "None"
    kubernetes_version         = "1.28.5"
    log_analytics_workspace_id = module.la.log_aw_id
  }

  rg_name  = module.rg.name
  location = module.metadata.location

  network_settings = {
    network_plugin  = "azure"
    pod_cidr        = null
    appgw_subnet_id = "/subscriptions/3c51cc28-d5df-44bb-b15c-cfdd64fff599/resourceGroups/RGSPOKE-CENTRALUS-VDC-SERVICES-MODEL/providers/Microsoft.Network/virtualNetworks/vnet-centralus-vdc-services-model/subnets/services-web-ingress-appgw-1"
  }

  create_groups                       = true
  workload_autoscaler_profile_enabled = true
  workload_autoscaler_profile = {
    keda_enabled = true
  }
  auto_scaler_profile_enabled = false
  default_node_pool = {
    name       = "default"
    subnet_id  = local.nodes_subnet_id
    node_count = 1
  }

  # Example values if not specified in maintenace_window
  maintenance_window = {
    allowed = [
      {
      day = "Monday"
      hours = [1, 2, 3]
    }
    ]
    not_allowed = [
      {
        start = 2025-06-01T00:00:00Z
        end   = 2025-06-01T02:00:00Z
      }
    ]
  }

# maintenance_window_auto_upgrade
  maintenance_window_auto_upgrade = {
    channel      = "Stable"
    frequency    = "Weekly"
    interval     = 2
    duration     = 8
    day_of_week  = "Friday"
    day_of_month = 5
    start_time   = "06:00"
    utc_offset   = "UTC+03:00"
    start_date   = "2025-05-01"
    not_allowed  = [
      {
        start = "06:00"
        end   = "07:00"
      }
    ]
  }

# maintenance_window_node_os
  maintenance_window_node_os = {
    channel      = "Stable"
    frequency    = "Weekly"
    interval     = 2
    duration     = 8
    day_of_week  = "Friday"
    day_of_month = 5
    start_time   = "06:00"
    utc_offset   = "UTC+03:00"
    start_date   = "2025-05-01"
    not_allowed  = [
      {
        start = "06:00"
        end   = "07:00"
      }
    ]
  }


  key_vault_secrets_provider_enabled = true

  key_vault_secrets_provider = {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  tags = local.tags
}

output "aks_name" {
  value = module.aks-cep.cluster_name
}

output "aks_cluster_id" {
  value = module.aks-cep.cluster_id
}

output "aks_cluster_admin_host" {
  value     = module.aks-cep.cluster_admin_host
  sensitive = true
}

output "aks_cluster_admin_client_certificate" {
  value     = module.aks-cep.cluster_admin_client_certificate
  sensitive = true
}

output "aks_cluster_admin_client_key" {
  value     = module.aks-cep.cluster_admin_client_key
  sensitive = true
}

output "aks_cluster_admin_ca_certificate" {
  value     = module.aks-cep.cluster_admin_ca_certificate
  sensitive = true
}

output "aks_tags" {
  value = module.aks-cep.tags
}

output "kube_config" {
  value     = module.aks-cep.kube_config
  sensitive = true
}