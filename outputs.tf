output "bastion_floating_ip" {
  value = openstack_networking_floatingip_v2.bastion_fip.address
}

output "nat_floating_ip" {
  value = openstack_networking_floatingip_v2.nat_fip.address
}

output "web_server_private_ip" {
  value = openstack_networking_port_v2.web_port.all_fixed_ips[0]
}

output "web_private_ip" {
  value = openstack_networking_port_v2.web_port.all_fixed_ips[0]
}

output "alb_floating_ip" {
  value = openstack_networking_floatingip_v2.alb_fip.address
}

output "alb_vip_address" {
  description = "ALB VIP 주소"
  value = openstack_lb_loadbalancer_v2.alb.vip_address
}

output "alb_id" {
  description = "ALB ID"
  value = openstack_lb_loadbalancer_v2.alb.id
}

output "k8s_master_private_ip" {
  value = openstack_networking_port_v2.k8s_master_port.all_fixed_ips[0]
}

output "k8s_slave_private_ips" {
  value = [for p in openstack_networking_port_v2.k8s_slave_port : p.all_fixed_ips[0]]
}

# 접속 정보
output "access_info" {
  description = "서비스 접속 정보"
  value = {
    web_app = "http://${openstack_networking_floatingip_v2.alb_fip.address}"
    bastion_ssh = "ssh ubuntu@${openstack_networking_floatingip_v2.bastion_fip.address}"
    web_ssh = "ssh -p 10000 ubuntu@${openstack_networking_floatingip_v2.bastion_fip.address}"
    k8s_master_ssh = "ssh -p 10001 ubuntu@${openstack_networking_floatingip_v2.bastion_fip.address}"
  }
}
