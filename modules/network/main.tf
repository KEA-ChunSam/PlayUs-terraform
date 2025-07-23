terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = ">= 1.40.0"
    }
  }
}

# public subnet 정보 조회 
data "openstack_networking_subnet_v2" "public_subnet" {
  subnet_id = var.public_subnet_id
}

# private subnet 정보 조회
data "openstack_networking_subnet_v2" "private_subnet" {
  subnet_id = var.private_subnet_id
}

#외부 네트워크 (Floating IP 풀) 조회 
data "openstack_networking_network_v2" "floating_network" {
  external = true
}

# Bastion용 Floating IP 생성
resource "openstack_networking_floatingip_v2" "bastion_fip" {
  pool = data.openstack_networking_network_v2.floating_network.name
}

# NAT용 Floating IP 생성
resource "openstack_networking_floatingip_v2" "nat_fip" {
  pool = data.openstack_networking_network_v2.floating_network.name
}

# Bastion 서버 포트 생성 
resource "openstack_networking_port_v2" "bastion_port" {
  name           = "${var.prefix}-bastion-port"
  network_id     = data.openstack_networking_subnet_v2.public_subnet.network_id
  admin_state_up = true

  security_group_ids = [
    var.bastion_security_group_id
  ]

  fixed_ip {
    subnet_id = var.public_subnet_id
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

  security_group_ids = [var.nat_security_group_id]
}

resource "openstack_networking_port_v2" "web_port" {
  name               = "${var.prefix}-web-port"
  network_id         = data.openstack_networking_subnet_v2.private_subnet.network_id
  admin_state_up     = true
  security_group_ids = [var.web_security_group_id]

  fixed_ip {
    subnet_id = var.private_subnet_id
  }
}

resource "openstack_networking_port_v2" "k8s_master_port" {
  name               = "${var.prefix}-k8s-master-port"
  network_id         = data.openstack_networking_subnet_v2.private_subnet.network_id
  admin_state_up     = true
  security_group_ids = [var.k8s_security_group_id]

  fixed_ip {
    subnet_id = var.private_subnet_id
  }
}

resource "openstack_networking_port_v2" "k8s_worker_port" {
  count              = 2
  name               = "${var.prefix}-k8s-worker-port-${count.index + 1}"
  network_id         = data.openstack_networking_subnet_v2.private_subnet.network_id
  admin_state_up     = true
  security_group_ids = [var.k8s_security_group_id]

  fixed_ip {
    subnet_id = var.private_subnet_id
  }
}
