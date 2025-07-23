output "bastion_instance_id" {
  description = "Bastion 인스턴스 ID"
  value       = openstack_compute_instance_v2.bastion.id
}

output "web_instance_id" {
  description = "Web 인스턴스 ID"
  value       = openstack_compute_instance_v2.web.id
}

output "nat_instance_id" {
  description = "NAT 인스턴스 ID"
  value       = openstack_compute_instance_v2.nat.id
}

output "nat_instance_private_ip" {
  description = "NAT 인스턴스 Private IP"
  value       = openstack_compute_instance_v2.nat.network[0].fixed_ip_v4
}

output "k8s_master_instance_id" {
  description = "K8s Master 인스턴스 ID"
  value       = openstack_compute_instance_v2.k8s_master.id
}

output "k8s_slave_instance_ids" {
  description = "K8s Slave 인스턴스 ID list"
  value       = openstack_compute_instance_v2.k8s_slave[*].id
}
