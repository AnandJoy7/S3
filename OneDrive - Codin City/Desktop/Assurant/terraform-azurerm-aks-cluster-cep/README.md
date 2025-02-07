# terraform-azurerm-aks-cluster-cep
Link to Confluence Pattern: https://confluence.assurant.com/display/aecpe/Azure+Kubernetes+Services+%28AKS%29+Design

## Summary
This pattern deploys an Azure Kubernetes Services (AKS).

## Scenario
<img alt="terraform-azurerm-aks-cluster-cep" src="https://documents.lucid.app/documents/a801faed-a0ca-4deb-ba8e-fb239c232980/pages/0_0?a=484&x=130&y=50&w=1100&h=1100&store=1&accept=image%2F*&auth=LCA%206b23a6f725ce957a98721ccffa940ddb1498658d-ts%3D1632404274">

## Benefits
* Azure Kubernetes Services cluster that meets assurant enterprise standards

## Feature Implementation Matrix
The following table highlights high level features and their implementation status. Additional features will be implemented based on identified user requirements.
| Feature | Status |
|---|---|
| AKS Private cluster must be enabled | Implemented |

## Pre-requisites
* Resource Group to deploy the resources
* Subnet details for private endpoints
* A subnet with adequate IP space especially for Azure CNI network (please see https://learn.microsoft.com/en-us/azure/aks/configure-azure-cni)

## Supported Terraform version: {TF version}

| Provider | Version |
|---|---|
| `azurerm` | `>= 3.90.0, < 5.0` |
| `azuread` | `~> 2.0` |

## Usage

Please see `/examples` directory for a list of examples using the module.

## Notable
 `node_count` property must be set in all cases for all the node pools. Setting this value to null could cause an erratic behavior on future updates.
  `appgw_subnet_id` property must be set to enable ingress application gateway

## Known Issues

## Azure RBAC
The following groups/roles can be provisioned by this module. By default, only the most common groups/roles are provisioned. Override the `groups` variable to opt in to additional supported groups/roles that your team needs.
| Group/Role | AAD Group Format | Default | Purpose |
|---|---|---|---|
| AAD-<cluster name>-ClusterAdmin | True | List cluster admin credential action |
| AAD-<cluster name>-ClusterUser | True | List cluster user credential action |
| AAD-<cluster name>-ClusterContributor | True | Grants access to read and write Azure Kubernetes Service clusters |
| AAD-<cluster name>-RBACAdmin | True | Lets you manage all resources under cluster/namespace, except update or delete resource quotas and namespaces. |
| AAD-<cluster name>-RBACClusterAdmin | True | Lets you manage all resources in the cluster. |
| AAD-<cluster name>-RBACClusterReader | True | Allows read-only access to see most objects in a namespace |
| AAD-<cluster name>-RBACClusterWriter | True | Meant for service account to manage most objects in namespace |

## Inputs

| Name | Description |
|------|-------------|
|rg_name|Resource Group Name|
|location|Cluster Location|

##Cluster Configuration

| Name | Description |
|------|-------------|
|cluster_name|Cluster Name|
|local_account_disabled|Disable local account for node authentication|
|automatic_channel_upgrade|The upgrade channel for this Kubernetes Cluster. Possible values are patch, rapid, node-image and stable. Defaults to none.|
|log_analytics_workspace_id|Log Analytics workspace resource id|
|create_groups|Create RBAC Groups|
|network_plugin|Network plugin to use. Options: kubenet or azure (default)|

##Default Node Pool

| Name | Description |
|------|-------------|
|name|The name of the Node Pool which should be created within the Kubernetes Cluster|
|vm_size|The SKU which should be used for the Virtual Machines used in this Node Pool. Default to Standard_DS4_v2.|
|vm_type|The type of Default Node Pool for the Kubernetes Cluster must be VirtualMachineScaleSets to attach multiple node pools. Default to VirtualMachineScaleSets.|
|os_disk_size_gb|The Agent Operating System disk size in GB|
|subnet_id|The ID of the Subnet where this Node Pool should exist.|
|pod_subnet_id|The ID of the Subnet where the pods in the default Node Pool should exist.|
|enable_autoscaling|Whether to enable auto-scaler. Default to false.|
|max_pods| The maximum number of pods that can run on each agent. Default to 30.|
|node_count|The number of nodes which should exist within this Node Pool. Valid values are between 0 and 1000 (inclusive) for user pools and between 1 and 1000 (inclusive) for system pools. Default to 3.|
|autoscaling_min_nodes|The minimum number of nodes which should exist within this Node Pool. Valid values are between 0 and 1000 and must be less than or equal to max_count. Default to null.|
|autoscaling_max_nodes|The maximum number of nodes which should exist within this Node Pool. Valid values are between 0 and 1000 and must be greater than or equal to min_count. Default to 1.|
|kube_node_labels|A map of Kubernetes labels which should be applied to nodes in this Node Pool.|
|only_critical_addons_enabled|Enabling this option will taint default node pool with CriticalAddonsOnly=true:NoSchedule taint. Default to true.|

## Outputs

| Name | Description | Sensitive |
|------|-------------|-----------|
| cluster_id | Kubernetes Managed Cluster ID | No |
| cluster_name | The AKS cluster name generated | No |
| cluster_admin_host | Kubernetes cluster admin host | Yes |
| cluster_admin_client_certificate | Kubernetes cluster admin client certificate | Yes |
| cluster_admin_client_key | Kubernetes cluster admin client key | Yes |
| cluster_admin_ca_certificate | Kubernetes cluster admin Certificate Authority (CA) certificate | Yes |
| cluster_username | Kubernetes cluster admin username | Yes |
| cluster_password | Kubernetes cluster admin password | Yes |
| kube_config | Raw Cluster Kubeconfig | Yes |
| cluster_api_endpoint_public | The Public Cluster API endpoint of the cluster | No |
| cluster_api_endpoint_private | The Private Cluster API endpoint of the cluster | No |
| groups | Groups created when create_groups variable is set to true. | No |
| tags | Azure Tags | No |

## Terraform

### Modules

### Resources

| Resources |
|-----------|
| `azurerm_kubernetes_cluster` |
| `azurerm_user_assigned_identity` |
| `azuread_group` |
| `azurerm_role_assignment` |

## Owners

| Name |
|---|
| Sanjay Murugan |
| Sundaram Diraviam |

## CHANGELOG

***
### Version 3.100.0

* Updated AzureRM version to >= 3.90.0, < 5.0
* Renamed deprecated argument reference, retaining the same value.

### Version 3.2.1

* Removed application gateway subnet role assignment, it should be configured automatically through ingress app gw addon in aks cluster

### Version 3.2.0

* Added support for workload_autoscaler_profile and auto_scaler_profile
* Added application_gateway_id as input to aid existing gateway migration 
* Updated application gateway subnet role assignment, when application gateway is enabled

### Version 3.1.1

* Added support for default_tags and module related tags
* Removed azurerm_monitor_diagnostic_setting
* Added var.default_node_pool.temporary_name_for_rotation. This is needed when
  * Importing from aks-cep for the first time (only_critical_addons_enabled becomes true)
  * The following var.default_node_pool parameters change:
    * vm_size, subnet_id, max_pods, os_disk_size_gb

### Version 3.1.0

* Updated optional key_vault_secrets_provider for aks cluster
* Created network contributor azuread_group group and assigned Classic Network Contributor role 
* removed deprecated docker_bridge_cidr and azurerm_monitor_diagnostic_setting -> retention_policy

### Version 3.0.0

* Updated default sku_tier to "Standard".
* Removed deprecated block "addon_profile" and "role_based_access_control".
* Changed unsupported argument "user_assigned_identity_id" to "identity_ids" & "availability_zones" to "zones".
* Updated "azure_active_directory_role_based_access_control" block for admin group access.
* Removed oms agent for the Cluster.
