resource "openstack_objectstorage_container_v1" "s3_bucket" {
  name = var.s3_bucket_name
}
