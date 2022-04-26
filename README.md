# Terraform GitHub Actions CI/CD demo
Deploying infrastructure with Terraform

## Objective

The objective of this repo is to demo and discuss the capabilities and advantages of deploying Azure services using Terraform and GitHub actions to different environments.

## Main Terraform concepts to explore

- Terraform setup on Azure
  - Service Principal Authentication
  - State file
- Providers
- Variables
- Resources
- Dependencies
- Naming
- Terraform development workflow

## GitHub concepts to explore

- GitHub Actions workflows
- Secrets
- Branch protection
- Environments

## Requirements

- Development experience (variables, conditional statements, control statements, etc.)
- DevOps experience (if you want to create the entire pipeline)

## Terraform infra code

```hcl
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
```

## GitHub Action workflow

```yaml
name: 'Terraform Plan/Apply'

on:
  push:
    branches:
    - main
  pull_request:
    branches:
    - main

permissions:
  contents: read

jobs:
  terraform:
    name: 'Terraform'
    env:
      ARM_CLIENT_ID: ${{ secrets.SERVICE_PRINCIPAL_CLIENT_ID }}
      ARM_CLIENT_SECRET: ${{ secrets.SERVICE_PRINCIPAL_CLIENT_SECRET }}
      ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      ARM_TENANT_ID: ${{ secrets.SERVICE_PRINCIPAL_TENANT_ID }}
      TF_VAR_administrator_login: ${{ secrets.ADMINISTRATOR_LOGIN }}
      TF_VAR_administrator_login_password: ${{ secrets.ADMINISTRATOR_LOGIN_PASSWORD }}
      
    runs-on: ubuntu-latest
    environment: nonprod    

    # Use the Bash shell regardless whether the GitHub Actions runner is ubuntu-latest, macos-latest, or windows-latest
    defaults:
      run:
        shell: bash
        working-directory: ./Terraform

    steps:
    # Checkout the repository to the GitHub Actions runner
    - name: Checkout
      uses: actions/checkout@v3

    # Install the latest version of Terraform CLI and configure the Terraform CLI configuration file with a Terraform Cloud user API token
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2

    # Initialize a new or existing Terraform working directory by creating initial files, loading any remote state, downloading modules, etc.
    - name: Terraform Init
      run: terraform init

    # Checks that all Terraform configuration files adhere to a canonical format
    - name: Terraform Format
      run: terraform fmt -check

    # Generates an execution plan for Terraform
    - name: Terraform Plan
      run: terraform plan -input=false

    # On push to main, build or change infrastructure according to Terraform configuration files
    - name: Terraform Apply
      if: github.ref == 'refs/heads/main' && github.event_name == 'push'
      run: terraform apply -auto-approve -input=false
```