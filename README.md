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

## Terraform setup on Azure
### Terraform State file (tfstate)
In order to remotely mantain the state of the infrastructure, Terraform needs to know where to store the state file.
You'll need to create a couple resources in Azure to store it.

Guidance on [How to login into Azure CLI](https://docs.microsoft.com/en-us/cli/azure/login?view=azure-cli-latest)

Once logged in on Azure CLI, go ahead and create a resource group and a storage account.

```bash
# Create a resource group
az group create -n <name> -l <location>

# Create a storage account
az storage account create -n <name> -g <resource_group_name> -l <location> --sku <sku>

# Create a storage container, you'll need to provide an access key
# more about the access key: https://docs.microsoft.com/en-us/cli/azure/storage/container?view=azure-cli-latest#az-storage-container-create
az storage container create -n <name> --account-name <account_name>  --account-key <key>
```
Once you create your resources you can replace the content from Terraform\backend.tf with your own values.

### Service Principal Authentication
The recommended way to interact with Terraform CLI is through a Service Principal.
You can also create one using the Azure CLI.

```bash
# Create a Service Principal
# How to find your subscription id: https://docs.microsoft.com/en-us/azure/azure-portal/get-subscription-tenant-id
az ad sp create-for-rbac --name "sp-terraform-demo-contributor" --role="Contributor" --scopes="/subscriptions/<your_subscription_id>"
```
This will prompt you an object with the following information, be sure to store it somewhere safe since you'll need it on next step

```json
{
  "appId": "your_sp_app_id",
  "displayName": "sp-terraform-demo-contributor",
  "password": "some_secret_password",
  "tenant": "some_tenant_id"
}
```

### GitHub secrets
In order to securely pass the credentials to Terraform, you'll need to create some GitHub secrets.
Go ahead and create the following secrets and use the values from the previous step.

- AZURE_SUBSCRIPTION_ID
- SERVICE_PRINCIPAL_CLIENT_ID
- SERVICE_PRINCIPAL_CLIENT_SECRET
- SERVICE_PRINCIPAL_TENANT_ID

Guidance on [How to create a GitHub secret](https://github.com/Azure/actions-workflow-samples/blob/master/assets/create-secrets-for-GitHub-workflows.md) 

We use these secrets in [terraform.yml](.github/workflows/terraform.yml) to pass the credentials to Terraform.
```yml
# extract from .github/workflows/terraform.yml
ARM_CLIENT_ID: ${{ secrets.SERVICE_PRINCIPAL_CLIENT_ID }}
ARM_CLIENT_SECRET: ${{ secrets.SERVICE_PRINCIPAL_CLIENT_SECRET }}
ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
ARM_TENANT_ID: ${{ secrets.SERVICE_PRINCIPAL_TENANT_ID }}
```

### Terraform Variables
In order to deploy the infrastructure, you'll need to create some variables, on this example we need to pass the login username and password of a PostgreSQL server.

Note that on [terraform.yml](.github/workflows/terraform.yml) we're creating two variables but not assigning any value to them. This is because we want to pass the values from the pipeline using secrets.

This could also be achieved generating a random string and storing it on key vault, but not covered on this demo.

```hcl
# extract from .github/workflows/terraform.yml

variable "administrator_login" {
  description = "The administrator login for the PostgreSQL server"
  type        = string
  sensitive   = true
}

variable "administrator_login_password" {
  description = "The administrator password for the PostgreSQL server"
  type        = string
  sensitive   = true
}
```

Go ahead and add two new secrets to your repo
- ADMINISTRATOR_LOGIN
- ADMINISTRATOR_LOGIN_PASSWORD

Once you have the secrets, you can also add them to the GitHub actions workflow as follows:

```yml
# extract from .github/workflows/terraform.yml
TF_VAR_administrator_login: ${{ secrets.ADMINISTRATOR_LOGIN }}
TF_VAR_administrator_login_password: ${{ secrets.ADMINISTRATOR_LOGIN_PASSWORD }}
```