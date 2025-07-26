output "bastion_port_id" {
  description = "Bastion 포트 ID"
  value       = openstack_networking_port_v2.bastion_port.id
}

output "bastion_floating_ip" {
  description = "Bastion Floating IP 주소"
  value       = openstack_networking_floatingip_v2.bastion_fip.address
}

output "nat_port_id" {
  description = "NAT 포트 ID"
  value       = openstack_networking_port_v2.nat_port.id
}

output "nat_floating_ip" {
  description = "NAT Floating IP 주소"
  value       = openstack_networking_floatingip_v2.nat_fip.address
}

output "web_port_id" {
  description = "Web 포트 ID"
  value       = openstack_networking_port_v2.web_port.id
}

output "web_port_private_ip" {
  description = "Web 포트 Private IP"
  value       = openstack_networking_port_v2.web_port.all_fixed_ips[0]
}

output "k8s_master_port_id" {
  description = "K8s Master 포트 ID"
  value       = openstack_networking_port_v2.k8s_master_port.id
}

output "k8s_master_port_private_ip" {
  description = "K8s Master 포트 Private IP"
  value       = openstack_networking_port_v2.k8s_master_port.all_fixed_ips[0]
}

output "k8s_worker_port_ids" {
  description = "K8s Worker 포트 ID list"
  value       = openstack_networking_port_v2.k8s_worker_port[*].id
}

output "k8s_worker_port_private_ips" {
  description = "K8s Worker 포트 Private IP list"
  value       = openstack_networking_port_v2.k8s_worker_port[*].all_fixed_ips[0]
}

output "floating_network_name" {
  description = "Floating 네트워크 이름"
  value       = data.openstack_networking_network_v2.floating_network.name
}
