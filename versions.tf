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

provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = var.vsphere_allow_unverified_ssl
}
