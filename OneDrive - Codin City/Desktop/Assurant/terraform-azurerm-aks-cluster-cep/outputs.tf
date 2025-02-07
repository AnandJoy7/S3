output "cluster_id" {
  description = "Kubernetes Managed Cluster ID"
  value       = azurerm_kubernetes_cluster.cluster.id
}

output "cluster_name" {
  description = "The AKS cluster name generated"
  value       = azurerm_kubernetes_cluster.cluster.name
}

output "cluster_admin_host" {
  description = "Kubernetes cluster admin host"
  value       = azurerm_kubernetes_cluster.cluster.kube_admin_config[0].host
  sensitive   = true
}

output "cluster_admin_client_certificate" {
  description = "Kubernetes cluster admin client certificate"
  value       = azurerm_kubernetes_cluster.cluster.kube_admin_config[0].client_certificate
  sensitive   = true
}

output "cluster_admin_client_key" {
  description = "Kubernetes cluster admin client key"
  value       = azurerm_kubernetes_cluster.cluster.kube_admin_config[0].client_key
  sensitive   = true
}

output "cluster_admin_ca_certificate" {
  description = "Kubernetes cluster admin Certificate Authority (CA) certificate"
  value       = azurerm_kubernetes_cluster.cluster.kube_admin_config[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_username" {
  description = "Kubernetes cluster admin username"
  value       = azurerm_kubernetes_cluster.cluster.kube_admin_config[0].username
  sensitive   = true
}

output "cluster_password" {
  description = "Kubernetes cluster admin password"
  value       = azurerm_kubernetes_cluster.cluster.kube_admin_config[0].password
  sensitive   = true
}

output "kube_config" {
  description = "Raw Cluster Kubeconfig"
  value       = azurerm_kubernetes_cluster.cluster.kube_admin_config_raw
  sensitive   = true
}

output "cluster_api_endpoint_public" {
  description = "The Public Cluster API endpoint of the cluster"
  value       = azurerm_kubernetes_cluster.cluster.fqdn
}

output "cluster_api_endpoint_private" {
  description = "The Private Cluster API endpoint of the cluster"
  value       = azurerm_kubernetes_cluster.cluster.private_fqdn
}

output "groups" {
  description = "Groups created when create_groups variable is set to true."
  value       = var.create_groups ? [for ag in azuread_group.AADGroups : ag.display_name] : []
}

output "tags" {
  description = "Azure Tags"
  value       = azurerm_kubernetes_cluster.cluster.tags
}