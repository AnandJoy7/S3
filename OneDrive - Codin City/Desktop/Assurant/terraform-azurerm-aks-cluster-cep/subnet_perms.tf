data "azurerm_subnet" "subnets" {
  name                 = local.subnet_id_array[10]
  virtual_network_name = local.subnet_id_array[8]
  resource_group_name  = local.subnet_id_array[4]
}

resource "azurerm_role_assignment" "udr_role" {
  count = var.network_settings.network_plugin != "azure" ? 1 : 0

  scope                = data.azurerm_subnet.subnets.route_table_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.user_mi.principal_id
}