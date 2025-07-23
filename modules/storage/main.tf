terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = ">= 1.40.0"
    }
  }
}

resource "openstack_objectstorage_container_v1" "s3_bucket" {
  name = var.s3_bucket_name
} 
