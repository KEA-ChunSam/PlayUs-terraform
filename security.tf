# 공통 보안 그룹 규칙
locals {
  common_egress_rule = {
    direction         = "egress"
    ethertype         = "IPv4"
    protocol          = null
    remote_ip_prefix  = "0.0.0.0/0"
  }
}

# Bastion 서버용 보안 그룹
resource "openstack_networking_secgroup_v2" "bastion_sg" {
  name        = "${var.prefix}-bastion-sg"
  description = "Security group for Bastion server"
}

# Bastion 보안 그룹 규칙
resource "openstack_networking_secgroup_rule_v2" "bastion_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.bastion_sg.id
  description       = "Allow SSH access from anywhere"
}

resource "openstack_networking_secgroup_rule_v2" "bastion_icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.bastion_sg.id
  description       = "Allow ICMP for network diagnostics"
}

resource "openstack_networking_secgroup_rule_v2" "bastion_egress" {
  for_each = { "all" = local.common_egress_rule }
  direction         = each.value.direction
  ethertype         = each.value.ethertype
  protocol          = each.value.protocol
  remote_ip_prefix  = each.value.remote_ip_prefix
  security_group_id = openstack_networking_secgroup_v2.bastion_sg.id
  description       = "Allow all outbound traffic"
}

# 웹 서버용 보안 그룹
resource "openstack_networking_secgroup_v2" "web_sg" {
  name        = "${var.prefix}-web-sg"
  description = "Security group for Web server"
  depends_on  = [openstack_networking_secgroup_v2.bastion_sg]
}

# 웹 서버 보안 그룹 규칙
resource "openstack_networking_secgroup_rule_v2" "web_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = openstack_networking_secgroup_v2.bastion_sg.id
  security_group_id = openstack_networking_secgroup_v2.web_sg.id
  description       = "Allow SSH access from Bastion server"
}

resource "openstack_networking_secgroup_rule_v2" "web_icmp" {
  for_each = {
    "bastion" = openstack_networking_secgroup_v2.bastion_sg.id
    "alb"     = openstack_networking_secgroup_v2.alb_sg.id
    "k8s"     = openstack_networking_secgroup_v2.k8s_sg.id
  }
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_group_id   = each.value
  security_group_id = openstack_networking_secgroup_v2.web_sg.id
  description       = "Allow ICMP for network diagnostics from ${each.key}"
  depends_on        = [
    openstack_networking_secgroup_v2.web_sg,
    openstack_networking_secgroup_v2.k8s_sg
  ]
}

resource "openstack_networking_secgroup_rule_v2" "web_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_group_id   = openstack_networking_secgroup_v2.alb_sg.id
  security_group_id = openstack_networking_secgroup_v2.web_sg.id
  description       = "Allow HTTP access from ALB"
}

resource "openstack_networking_secgroup_rule_v2" "web_egress" {
  for_each = { "all" = local.common_egress_rule }
  direction         = each.value.direction
  ethertype         = each.value.ethertype
  protocol          = each.value.protocol
  remote_ip_prefix  = each.value.remote_ip_prefix
  security_group_id = openstack_networking_secgroup_v2.web_sg.id
  description       = "Allow all outbound traffic"
}

# ALB 보안 그룹
resource "openstack_networking_secgroup_v2" "alb_sg" {
  name        = "${var.prefix}-alb-sg"
  description = "Security group for ALB"
}

# ALB 보안 그룹 규칙
resource "openstack_networking_secgroup_rule_v2" "alb_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.alb_sg.id
  description       = "Allow HTTP access from anywhere"
}

resource "openstack_networking_secgroup_rule_v2" "alb_icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.alb_sg.id
  description       = "Allow ICMP for network diagnostics"
}

resource "openstack_networking_secgroup_rule_v2" "alb_egress" {
  for_each = { "all" = local.common_egress_rule }
  direction         = each.value.direction
  ethertype         = each.value.ethertype
  protocol          = each.value.protocol
  remote_ip_prefix  = each.value.remote_ip_prefix
  security_group_id = openstack_networking_secgroup_v2.alb_sg.id
  description       = "Allow all outbound traffic"
}

# NAT 인스턴스 보안 그룹
resource "openstack_networking_secgroup_v2" "nat_sg" {
  name        = "${var.prefix}-nat-sg"
  description = "Security group for NAT instance (SNAT only)"
}

# NAT 보안 그룹 규칙
resource "openstack_networking_secgroup_rule_v2" "nat_ingress_private" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 1024
  port_range_max    = 65535
  remote_ip_prefix  = var.private_network_cidr
  security_group_id = openstack_networking_secgroup_v2.nat_sg.id
  description       = "Allow TCP traffic from private subnet for SNAT"
}

resource "openstack_networking_secgroup_rule_v2" "nat_ingress_private_udp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 1024
  port_range_max    = 65535
  remote_ip_prefix  = var.private_network_cidr
  security_group_id = openstack_networking_secgroup_v2.nat_sg.id
  description       = "Allow UDP traffic from private subnet for SNAT"
}

resource "openstack_networking_secgroup_rule_v2" "nat_icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = var.private_network_cidr
  security_group_id = openstack_networking_secgroup_v2.nat_sg.id
  description       = "Allow ICMP for network diagnostics from private subnet"
}

resource "openstack_networking_secgroup_rule_v2" "nat_egress" {
  for_each = { "all" = local.common_egress_rule }
  direction         = each.value.direction
  ethertype         = each.value.ethertype
  protocol          = each.value.protocol
  remote_ip_prefix  = each.value.remote_ip_prefix
  security_group_id = openstack_networking_secgroup_v2.nat_sg.id
  description       = "Allow all outbound traffic for SNAT"
}

# Kubernetes 보안 그룹
resource "openstack_networking_secgroup_v2" "k8s_sg" {
  name        = "${var.prefix}-k8s-sg"
  description = "Security group for Kubernetes nodes"
  depends_on  = [
    openstack_networking_secgroup_v2.bastion_sg,
    openstack_networking_secgroup_v2.web_sg
  ]
}

# Kubernetes 보안 그룹 규칙
resource "openstack_networking_secgroup_rule_v2" "k8s_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = openstack_networking_secgroup_v2.bastion_sg.id
  security_group_id = openstack_networking_secgroup_v2.k8s_sg.id
  description       = "Allow SSH access from Bastion server"
}

resource "openstack_networking_secgroup_rule_v2" "k8s_icmp" {
  for_each = {
    "bastion" = openstack_networking_secgroup_v2.bastion_sg.id
    "web"     = openstack_networking_secgroup_v2.web_sg.id
    "k8s"     = openstack_networking_secgroup_v2.k8s_sg.id
  }
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_group_id   = each.value
  security_group_id = openstack_networking_secgroup_v2.k8s_sg.id
  description       = "Allow ICMP for network diagnostics from ${each.key}"
  depends_on        = [
    openstack_networking_secgroup_v2.k8s_sg,
    openstack_networking_secgroup_v2.web_sg
  ]
}

resource "openstack_networking_secgroup_rule_v2" "k8s_internal" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 1024
  port_range_max    = 65535
  remote_group_id   = openstack_networking_secgroup_v2.k8s_sg.id
  security_group_id = openstack_networking_secgroup_v2.k8s_sg.id
  description       = "Allow internal k8s node communication"
}

resource "openstack_networking_secgroup_rule_v2" "k8s_api" {
  for_each = {
    "bastion" = openstack_networking_secgroup_v2.bastion_sg.id
    "web"     = openstack_networking_secgroup_v2.web_sg.id
  }
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_group_id   = each.value
  security_group_id = openstack_networking_secgroup_v2.k8s_sg.id
  description       = "Allow k8s API access from ${each.key} server"
  depends_on        = [openstack_networking_secgroup_v2.k8s_sg]
}

resource "openstack_networking_secgroup_rule_v2" "k8s_nodeport" {
  for_each = {
    "web" = openstack_networking_secgroup_v2.web_sg.id
    "k8s" = openstack_networking_secgroup_v2.k8s_sg.id
  }
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 30000
  port_range_max    = 32767
  remote_group_id   = each.value
  security_group_id = openstack_networking_secgroup_v2.k8s_sg.id
  description       = "Allow NodePort access from ${each.key}"
  depends_on        = [openstack_networking_secgroup_v2.k8s_sg]
}

resource "openstack_networking_secgroup_rule_v2" "k8s_egress" {
  for_each = { "all" = local.common_egress_rule }
  direction         = each.value.direction
  ethertype         = each.value.ethertype
  protocol          = each.value.protocol
  remote_ip_prefix  = each.value.remote_ip_prefix
  security_group_id = openstack_networking_secgroup_v2.k8s_sg.id
  description       = "Allow all outbound traffic"
}
