# public subnet 정보 조회 
data "openstack_networking_subnet_v2" "public_subnet" {
  subnet_id = var.public_subnet_id 
}

# private subnet 정보 조회
data "openstack_networking_subnet_v2" "private_subnet" {
  subnet_id = var.private_subnet_id
}

# 외부 네트워크 (Floating IP 풀) 조회
data "openstack_networking_network_v2" "floating_network" {
  external = true
}

# Bastion용 Floating IP 생성
resource "openstack_networking_floatingip_v2" "bastion_fip" {
  pool = data.openstack_networking_network_v2.floating_network.name
}

# Bastion 서버 포트 생성 
resource "openstack_networking_port_v2" "bastion_port" {
  name           = "${var.prefix}-bastion-port"
  network_id     = data.openstack_networking_subnet_v2.public_subnet.network_id
  admin_state_up = true

  security_group_ids = [
    openstack_networking_secgroup_v2.bastion_sg.id
  ]

  fixed_ip {
    subnet_id = var.public_subnet_id
  }
}

# Bastion Floating IP 연결
resource "openstack_networking_floatingip_associate_v2" "bastion_fip_assoc" {
  floating_ip = openstack_networking_floatingip_v2.bastion_fip.address
  port_id     = openstack_networking_port_v2.bastion_port.id
}

# 웹 서버용 포트 생성
resource "openstack_networking_port_v2" "web_port" {
  name               = "${var.prefix}-web-port"
  network_id         = data.openstack_networking_subnet_v2.private_subnet.network_id
  admin_state_up     = true
  security_group_ids = [openstack_networking_secgroup_v2.web_sg.id]

  fixed_ip {
    subnet_id = var.private_subnet_id
  }
}

# NAT용 포트 생성
resource "openstack_networking_port_v2" "nat_port" {
  name           = "${var.prefix}-nat-port"
  network_id     = data.openstack_networking_subnet_v2.public_subnet.network_id
  admin_state_up = true

  fixed_ip {
    subnet_id = var.public_subnet_id
  }

  security_group_ids = [openstack_networking_secgroup_v2.nat_sg.id]
}

# NAT용 Floating IP 생성
resource "openstack_networking_floatingip_v2" "nat_fip" {
  pool    = data.openstack_networking_network_v2.floating_network.name
  port_id = openstack_networking_port_v2.nat_port.id
}

resource "openstack_networking_port_v2" "k8s_master_port" {
  name               = "${var.prefix}-k8s-master-port"
  network_id         = data.openstack_networking_subnet_v2.private_subnet.network_id
  admin_state_up     = true
  security_group_ids = [openstack_networking_secgroup_v2.k8s_sg.id]
  fixed_ip {
    subnet_id = var.private_subnet_id
  }
}

resource "openstack_networking_port_v2" "k8s_slave_port" {
  count              = 2
  name               = "${var.prefix}-k8s-slave-port-${count.index + 1}"
  network_id         = data.openstack_networking_subnet_v2.private_subnet.network_id
  admin_state_up     = true
  security_group_ids = [openstack_networking_secgroup_v2.k8s_sg.id]
  fixed_ip {
    subnet_id = var.private_subnet_id
  }
}

# 프라이빗 라우팅 테이블에 NAT 인스턴스를 통한 라우팅 규칙 추가
resource "openstack_networking_router_route_v2" "private_route" {
  router_id        = "bce6ea9c-d831-4139-a687-1b05bfd51857"  # 프라이빗 라우팅 테이블 ID
  destination_cidr = "0.0.0.0/0"
  next_hop         = openstack_networking_port_v2.nat_port.all_fixed_ips[0]
}
