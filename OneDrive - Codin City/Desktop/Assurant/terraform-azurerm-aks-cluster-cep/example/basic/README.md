### Example: Basic Example

```terraform
provider "azurerm" {
  features {}
}

locals {
  tags = {
    App_Name             = "terratest"
    App_Env              = "test"
    ServiceNow_Workgroup = "None"
  }

  nodes_subnet_id = "/subscriptions/3c51cc28-d5df-44bb-b15c-cfdd64fff599/resourceGroups/RGSPOKE-CENTRALUS-VDC-SERVICES-MODEL/providers/Microsoft.Network/virtualNetworks/vnet-centralus-vdc-services-model/subnets/kubernetes-services-1"
}

module "rg" {
  source = "app.terraform.io/AIZ/resourcegroup-cep/azurerm"

  location      = "East US"
  create_groups = true # Default is true, see notes
  assign_roles  = true # Default is true, see notes

  tags = local.tags
}

module "la" {
  source = "app.terraform.io/AIZ/log-analytics-cep/azurerm"

  rg_name           = module.rg.name
  aw_name           = local.tags["App_Name"]
  location          = "East US"
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
  source = "../../"

  aks_cluster = {
    cluster_name               = local.tags["App_Env"]
    automatic_channel_upgrade  = "patch"
    kubernetes_version         = "1.28.5"
    log_analytics_workspace_id = module.la.log_aw_id
  }

  rg_name  = module.rg.name
  location = module.metadata.location

  network_settings = {
    network_plugin                      = "azure"
    pod_cidr                            = null
    ingress_application_gateway_enabled = true
    appgw_subnet_id                     = "/subscriptions/3c51cc28-d5df-44bb-b15c-cfdd64fff599/resourceGroups/RGSPOKE-CENTRALUS-VDC-SERVICES-MODEL/providers/Microsoft.Network/virtualNetworks/vnet-centralus-vdc-services-model/subnets/services-web-ingress-appgw-1"
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
    node_count = 2
  }

  key_vault_secrets_provider_enabled = true

  key_vault_secrets_provider = {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }
  
  tags = local.tags
}
```