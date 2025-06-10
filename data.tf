locals {
  # 모든 인스턴스 초기화 스크립트
  bastion_init = file("${path.module}/templates/init-bastion.sh")
  nat_init = file("${path.module}/templates/init-nat.sh")
  k8s_master_init = file("${path.module}/templates/init-k8s-master.sh")
  k8s_slave_init = file("${path.module}/templates/init-k8s-slave.sh")
  web_init = file("${path.module}/templates/init-web.sh")
  
  # 웹 서버 환경 변수 설정
  web_env = templatefile("${path.module}/templates/web-env.sh", {
    APP_ENDPOINT = "http://${openstack_lb_loadbalancer_v2.alb.vip_address}"
  })
}

# SSH Keypair 정보 가져오기
data "openstack_compute_keypair_v2" "ssh_key" {
  name = var.ssh_key_name
}