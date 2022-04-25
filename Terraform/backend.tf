# Stores the state as a Blob with the given Key within the Blob Container within the Blob Storage Account
# This backend supports state locking and consistency checking with Azure Blob Storage native capabilities
terraform {
  backend "azurerm" {
    resource_group_name  = "demotfstates"
    storage_account_name = "demotf"
    container_name       = "tfstategithub"
    key                  = "tfstategithub.terraform.tfstate"
  }
}