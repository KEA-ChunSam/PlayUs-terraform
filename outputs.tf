output "bastion_floating_ip" {
  value = openstack_networking_floatingip_v2.bastion_fip.address
}

output "nat_floating_ip" {
  value = openstack_networking_floatingip_v2.nat_fip.address
}

output "web_private_ip" {
  value = openstack_networking_port_v2.web_port.all_fixed_ips[0]
}

output "alb_floating_ip" {
  value = openstack_networking_floatingip_v2.alb_fip.address
}

output "k8s_master_private_ip" {
  value = openstack_networking_port_v2.k8s_master_port.all_fixed_ips[0]
}

output "k8s_slave_private_ips" {
  value = [for p in openstack_networking_port_v2.k8s_slave_port : p.all_fixed_ips[0]]
}
