output "s3_bucket_name" {
  description = "S3 버킷 이름"
  value       = openstack_objectstorage_container_v1.s3_bucket.name
} 
