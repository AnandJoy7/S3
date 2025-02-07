#Create the new AAD Groups
resource "azuread_group" "AADGroups" {
  for_each = local.groups

  display_name            = upper("AAD-aks-${var.aks_cluster.cluster_name}-${each.key}")
  description             = each.value
  prevent_duplicate_names = true
  security_enabled        = true
}

#Assign the appropriate built-in RBAC role to the new group at the scope of the new resource group
resource "azurerm_role_assignment" "AADRBAC" {
  for_each = local.groups

  scope                = azurerm_kubernetes_cluster.cluster.id
  role_definition_name = each.value
  principal_id         = azuread_group.AADGroups[each.key].id
}