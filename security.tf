# Bastion 서버용 보안 그룹 생성
resource "openstack_networking_secgroup_v2" "bastion_sg" {
  name        = "${var.prefix}-bastion-sg"
  description = "Security group for Bastion"
}

# SSH 포트 허용 (Bastion IP에서만)
resource "openstack_networking_secgroup_rule_v2" "bastion-ssh-sg-rule" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.bastion_sg.id
}

# 관리자 포트 허용 (Bastion IP에서만)
resource "openstack_networking_secgroup_rule_v2" "bastion-admin-sg-rule" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 81
  port_range_max    = 81
  remote_ip_prefix  = "${openstack_networking_floatingip_v2.bastion_fip.address}/32"
  security_group_id = openstack_networking_secgroup_v2.bastion_sg.id
}

# 프록시 포트 허용 (Bastion IP에서만)
resource "openstack_networking_secgroup_rule_v2" "bastion-proxy-sg-rule" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10000
  port_range_max    = 10100
  remote_ip_prefix  = "${openstack_networking_floatingip_v2.bastion_fip.address}/32"
  security_group_id = openstack_networking_secgroup_v2.bastion_sg.id
}

# Bastion 아웃바운드 규칙 (필요한 서비스만 허용)
resource "openstack_networking_secgroup_rule_v2" "bastion_egress" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.bastion_sg.id
}

# 웹 서버용 보안 그룹 생성
resource "openstack_networking_secgroup_v2" "web_sg" {
  name        = "${var.prefix}-web-sg"
  description = "Security group for ${var.prefix}-Server"
}

# Bastion 서버에서 웹 서버로 SSH 포트 허용
resource "openstack_networking_secgroup_rule_v2" "web-sg-ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = openstack_networking_secgroup_v2.bastion_sg.id
  security_group_id = openstack_networking_secgroup_v2.web_sg.id
}

# ALB에서 웹 서버로 HTTP/HTTPS 접속 허용
resource "openstack_networking_secgroup_rule_v2" "web-sg-public" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 443
  remote_group_id   = openstack_networking_secgroup_v2.alb_sg.id
  security_group_id = openstack_networking_secgroup_v2.web_sg.id
}

# Web 서버 아웃바운드 규칙 (필요한 서비스만 허용)
resource "openstack_networking_secgroup_rule_v2" "web_sg_egress" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.web_sg.id
}

resource "openstack_networking_secgroup_v2" "alb_sg" {
  name        = "${var.prefix}-alb-sg"
  description = "ALB 보안 그룹"
}

# ALB HTTP/HTTPS 인바운드 규칙
resource "openstack_networking_secgroup_rule_v2" "alb_ingress_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.alb_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "alb_sg_icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.alb_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "alb_sg_egress" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = null
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.alb_sg.id
}

resource "openstack_networking_secgroup_v2" "nat_sg" {
  name        = "${var.prefix}-nat-sg"
  description = "Security group for NAT instance"
}

# NAT 인스턴스 인바운드 규칙 (프라이빗 서브넷에서만)
resource "openstack_networking_secgroup_rule_v2" "nat_sg_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 1024
  port_range_max    = 65535
  remote_ip_prefix  = var.private_network_cidr
  security_group_id = openstack_networking_secgroup_v2.nat_sg.id
}

# NAT 인스턴스 아웃바운드 규칙 (HTTP/HTTPS만)
resource "openstack_networking_secgroup_rule_v2" "nat_sg_egress" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.nat_sg.id
}

resource "openstack_networking_secgroup_v2" "k8s_sg" {
  name        = "${var.prefix}-k8s-sg"
  description = "Security group for k8s nodes"
}

# Bastion에서 k8s 노드로 SSH 허용
resource "openstack_networking_secgroup_rule_v2" "k8s_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = openstack_networking_secgroup_v2.bastion_sg.id
  security_group_id = openstack_networking_secgroup_v2.k8s_sg.id
}

# k8s 노드간 필요한 포트만 허용
resource "openstack_networking_secgroup_rule_v2" "k8s_internal" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 1024
  port_range_max    = 65535
  remote_group_id   = openstack_networking_secgroup_v2.k8s_sg.id
  security_group_id = openstack_networking_secgroup_v2.k8s_sg.id
}

# k8s 노드의 아웃바운드 규칙 (필요한 서비스만)
resource "openstack_networking_secgroup_rule_v2" "k8s_outbound" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_sg.id
}

# k8s API 서버 접근 규칙 (Bastion에서만)
resource "openstack_networking_secgroup_rule_v2" "k8s_api" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_group_id   = openstack_networking_secgroup_v2.bastion_sg.id
  security_group_id = openstack_networking_secgroup_v2.k8s_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "k8s_from_web_80" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_group_id   = openstack_networking_secgroup_v2.web_sg.id
  security_group_id = openstack_networking_secgroup_v2.k8s_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "k8s_from_web_443" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_group_id   = openstack_networking_secgroup_v2.web_sg.id
  security_group_id = openstack_networking_secgroup_v2.k8s_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "k8s_from_web_8080" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8080
  port_range_max    = 8080
  remote_group_id   = openstack_networking_secgroup_v2.web_sg.id
  security_group_id = openstack_networking_secgroup_v2.k8s_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "k8s_from_web_6443" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_group_id   = openstack_networking_secgroup_v2.web_sg.id
  security_group_id = openstack_networking_secgroup_v2.k8s_sg.id
}
