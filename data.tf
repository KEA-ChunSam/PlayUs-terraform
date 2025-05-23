locals {
  bastion_init = templatefile("${path.module}/scripts/init-bastion.sh", {
    web_server_ip = openstack_networking_port_v2.web_port.all_fixed_ips[0]
    k8s_master_ip = openstack_networking_port_v2.k8s_master_port.all_fixed_ips[0]
    k8s_slave1_ip = element(openstack_networking_port_v2.k8s_slave_port.*.all_fixed_ips[0], 0)
    k8s_slave2_ip = element(openstack_networking_port_v2.k8s_slave_port.*.all_fixed_ips[0], 1)
  })
}

# SSH Keypair 정보 가져오기
data "openstack_compute_keypair_v2" "ssh_key_name" {
  name = var.ssh_key_name
}

locals {
  web_env = templatefile("${path.module}/scripts/web-env.sh", {
    APP_ENDPOINT = "http://${openstack_lb_loadbalancer_v2.alb.vip_address}:8080"
  })
  web_init = file("${path.module}/scripts/init-web.sh")
}
