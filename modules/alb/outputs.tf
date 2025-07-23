output "alb_loadbalancer_id" {
  description = "ALB ID"
  value       = openstack_lb_loadbalancer_v2.alb.id
}

output "alb_floating_ip" {
  description = "ALB Floating IP 주소"
  value       = openstack_networking_floatingip_v2.alb_fip.address
}

output "alb_vip_port_id" {
  description = "ALB VIP 포트 ID"
  value       = openstack_lb_loadbalancer_v2.alb.vip_port_id
}
