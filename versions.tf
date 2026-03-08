terraform {
  required_version = ">= 1.3, < 2.0"

  # To use remote state, add a backend block here, e.g.:
  # backend "s3" {}
  # backend "azurerm" {}
  # See: https://developer.hashicorp.com/terraform/language/settings/backends/configuration

  required_providers {
    vsphere = {
      source  = "vmware/vsphere"
      version = "~> 2.6"
    }
  }
}
