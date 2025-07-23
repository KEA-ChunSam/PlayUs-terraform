output "bastion_security_group_id" {
  description = "Bastion 보안 그룹 ID"
  value       = openstack_networking_secgroup_v2.bastion_sg.id
}

output "web_security_group_id" {
  description = "Web 보안 그룹 ID"
  value       = openstack_networking_secgroup_v2.web_sg.id
}

output "alb_security_group_id" {
  description = "ALB 보안 그룹 ID"
  value       = openstack_networking_secgroup_v2.alb_sg.id
}

output "nat_security_group_id" {
  description = "NAT 보안 그룹 ID"
  value       = openstack_networking_secgroup_v2.nat_sg.id
}

output "k8s_security_group_id" {
  description = "Kubernetes 보안 그룹 ID"
  value       = openstack_networking_secgroup_v2.k8s_sg.id
}
