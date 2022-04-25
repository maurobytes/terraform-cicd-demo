locals {
  location     = "eastus2"
  project_name = "demo"
}

# Resource group
resource "azurerm_resource_group" "demo_rg" {
  for_each = local.environments
  name     = join("-", compact(["rg", local.project_name, each.key, local.location]))
  location = local.location
  tags = {
    environment = each.key
    project     = local.project_name
  }
}

# App Service Plan Linux
resource "azurerm_service_plan" "demo_asp" {
  for_each            = local.environments
  name                = join("-", compact(["asp", local.project_name, each.key, local.location]))
  resource_group_name = azurerm_resource_group.demo_rg[each.key].name
  location            = azurerm_resource_group.demo_rg[each.key].location
  os_type             = each.value.app_service_plan.os_type
  sku_name            = each.value.app_service_plan.sku_name

  tags = {
    environment = each.key
    project     = local.project_name
  }
}

# App Service
resource "azurerm_linux_web_app" "demo_app" {
  for_each            = local.environments
  name                = join("-", compact(["webapp", local.project_name, each.key, local.location]))
  location            = azurerm_resource_group.demo_rg[each.key].location
  resource_group_name = azurerm_resource_group.demo_rg[each.key].name
  service_plan_id     = azurerm_service_plan.demo_asp[each.key].id

  site_config {
    application_stack {
      node_version = "14-lts"
    }
  }
}

# PostgreSQL Server
resource "azurerm_postgresql_server" "demo_pgsql" {
  for_each                     = local.environments
  name                         = join("-", compact(["pgsql", local.project_name, each.key, local.location]))
  location                     = azurerm_resource_group.demo_rg[each.key].location
  resource_group_name          = azurerm_resource_group.demo_rg[each.key].name
  sku_name                     = "GP_Gen5_2" # Tier + family + cores pattern (e.g. B_Gen4_1, GP_Gen5_8)
  create_mode                  = "Default"
  version                      = "11"
  ssl_enforcement_enabled      = true
  administrator_login          = var.administrator_login
  administrator_login_password = var.administrator_login_password

  tags = {
    environment = each.key
    project     = local.project_name
  }
}

# PostgreSQL Database
resource "azurerm_postgresql_database" "demo_pgsql_db" {
  for_each            = local.environments
  name                = join("-", compact(["pgsqldb", local.project_name, each.key, local.location]))
  resource_group_name = azurerm_resource_group.demo_rg[each.key].name
  server_name         = azurerm_postgresql_server.demo_pgsql[each.key].name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}