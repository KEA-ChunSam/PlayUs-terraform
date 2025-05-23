terraform {
  required_version = ">= 1.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = ">= 1.40.0"
    }
  }
}

provider "openstack" {
  auth_url                    = var.auth_url
  application_credential_id   = var.application_credential_id
  application_credential_secret = var.application_credential_secret
  region                      = var.region
}
