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