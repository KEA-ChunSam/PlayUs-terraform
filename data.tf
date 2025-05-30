locals {
  # Bastion 초기화 스크립트
  bastion_init = file("${path.module}/templates/init-bastion.sh")
  
  # NAT 초기화 스크립트
  nat_init = file("${path.module}/templates/init-nat.sh")

  # K8s 마스터 초기화 스크립트
  k8s_master_init = file("${path.module}/templates/init-k8s-master.sh")
}

# SSH Keypair 정보 가져오기
data "openstack_compute_keypair_v2" "ssh_key" {
  name = var.ssh_key_name
}

locals {
  web_env = templatefile("${path.module}/templates/web-env.sh", {
    APP_ENDPOINT   = "http://${openstack_lb_loadbalancer_v2.alb.vip_address}"
    K8S_MASTER_IP  = openstack_networking_port_v2.k8s_master_port.all_fixed_ips[0]
  })
  web_init = file("${path.module}/templates/init-web.sh")
  
  # K8s 슬레이브 초기화 스크립트 (마스터 IP 포함)
  k8s_slave_init = templatefile("${path.module}/templates/init-k8s-slave.sh", {
    k8s_master_ip = openstack_networking_port_v2.k8s_master_port.all_fixed_ips[0]
  })
}
