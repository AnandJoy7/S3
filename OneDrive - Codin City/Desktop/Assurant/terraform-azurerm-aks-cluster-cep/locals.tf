locals {
  module_tags = {
    TFModule_Name    = "terraform-azurerm-aks-cluster-cep"
    TFModule_Version = "3.100.0"
  }

  # Groups that will receive Azure RBAC Roles
  groups = var.create_groups ? {
    #List cluster admin credential action
    "ClusterAdmin" = "Azure Kubernetes Service Cluster Admin Role"
    #List cluster user credential action
    "ClusterUser" = "Azure Kubernetes Service Cluster User Role"
    #Grants access to read and write Azure Kubernetes Service clusters
    "ClusterContributor" = "Azure Kubernetes Service Contributor Role"
    #Lets you manage networks, but not access to them.
    "NetworkContributor" = "Network Contributor"
    #Lets you manage all resources under cluster/namespace, except update or delete resource quotas and namespaces.
    "RBACAdmin" = "Azure Kubernetes Service RBAC Admin"
    #Lets you manage all resources in the cluster.
    "RBACClusterAdmin" = "Azure Kubernetes Service RBAC Cluster Admin"
    #Allows read-only access to see most objects in a namespace
    "RBACClusterReader" = "Azure Kubernetes Service RBAC Reader"
    #Allows read/write access to most objects in a namespace.This role does not allow viewing or modifying roles or role bindings. However, this role allows accessing Secrets and running Pods as any ServiceAccount in the namespace, so it can be used to gain the API access levels of any ServiceAccount in the namespace.
    "RBACClusterWriter" = "Azure Kubernetes Service RBAC Writer"
  } : {}

  subnet_id_array = split("/", var.default_node_pool.subnet_id)

  tags = merge(var.default_tags, var.tags, local.module_tags)
}