# Bastion 서버 정보
output "bastion_floating_ip" {
  description = "Bastion 서버 Floating IP"
  value       = module.network.bastion_floating_ip
}

output "bastion_instance_id" {
  description = "Bastion 인스턴스 ID"
  value       = module.compute.bastion_instance_id
}

# NAT 서버 정보
output "nat_floating_ip" {
  description = "NAT 서버 Floating IP"
  value       = module.network.nat_floating_ip
}

output "nat_instance_id" {
  description = "NAT 인스턴스 ID"
  value       = module.compute.nat_instance_id
}

# Web 서버 정보
output "web_instance_id" {
  description = "Web 인스턴스 ID"
  value       = module.compute.web_instance_id
}

# Kubernetes 정보
output "k8s_master_instance_id" {
  description = "Kubernetes Master 인스턴스 ID"
  value       = module.compute.k8s_master_instance_id
}

output "k8s_worker_instance_ids" {
  description = "Kubernetes Worker 인스턴스 ID list"
  value       = module.compute.k8s_worker_instance_ids
}

# ALB 정보
output "alb_floating_ip" {
  description = "ALB Floating IP"
  value       = module.alb.alb_floating_ip
}

output "alb_loadbalancer_id" {
  description = "ALB ID"
  value       = module.alb.alb_loadbalancer_id
}

# Storage 정보
output "s3_bucket_name" {
  description = "S3 버킷 이름"
  value       = module.storage.s3_bucket_name
}

# 보안 그룹 정보
output "bastion_security_group_id" {
  description = "Bastion 보안 그룹 ID"
  value       = module.security.bastion_security_group_id
}

output "web_security_group_id" {
  description = "Web 보안 그룹 ID"
  value       = module.security.web_security_group_id
}

output "alb_security_group_id" {
  description = "ALB 보안 그룹 ID"
  value       = module.security.alb_security_group_id
}

output "nat_security_group_id" {
  description = "NAT 보안 그룹 ID"
  value       = module.security.nat_security_group_id
}

output "k8s_security_group_id" {
  description = "Kubernetes 보안 그룹 ID"
  value       = module.security.k8s_security_group_id
}
