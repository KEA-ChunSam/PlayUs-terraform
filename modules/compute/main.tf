terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = ">= 1.40.0"
    }
  }
}

# Bastion 서버
resource "openstack_compute_instance_v2" "bastion" {
  name      = "${var.prefix}-bastion"
  image_id  = var.images.ubuntu.id
  flavor_id = var.instance_types.bastion.id
  key_pair  = var.ssh_key_name

  network {
    port = var.bastion_port_id
  }

  block_device {
    uuid                  = var.images.ubuntu.id
    source_type           = "image"
    volume_size           = 20
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }
}

# 웹 서버
resource "openstack_compute_instance_v2" "web" {
  name      = "${var.prefix}-web"
  image_id  = var.images.ubuntu.id
  flavor_id = var.instance_types.web.id
  key_pair  = var.ssh_key_name

  network {
    port = var.web_port_id
  }

  block_device {
    uuid                  = var.images.ubuntu.id
    source_type           = "image"
    volume_size           = 25
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }
}

# NAT 인스턴스 서버
resource "openstack_compute_instance_v2" "nat" {
  name      = "${var.prefix}-nat"
  image_id  = var.images.ubuntu.id
  flavor_id = var.instance_types.nat.id
  key_pair  = var.ssh_key_name

  network {
    port = var.nat_port_id
  }

  block_device {
    uuid                  = var.images.ubuntu.id
    source_type           = "image"
    volume_size           = 20
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }
}

# Kubernetes 마스터
resource "openstack_compute_instance_v2" "k8s_master" {
  name      = "${var.prefix}-k8s-master"
  image_id  = var.images.ubuntu.id
  flavor_id = var.instance_types.k8s_master.id
  key_pair  = var.ssh_key_name

  network {
    port = var.k8s_master_port_id
  }

  block_device {
    uuid                  = var.images.ubuntu.id
    source_type           = "image"
    volume_size           = 20
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }
}

# Kubernetes 워커 노드
resource "openstack_compute_instance_v2" "k8s_slave" {
  count     = 2
  name      = "${var.prefix}-k8s-slave-${count.index + 1}"
  image_id  = var.images.ubuntu.id
  flavor_id = var.instance_types.k8s_slave.id
  key_pair  = var.ssh_key_name

  network {
    port = var.k8s_slave_port_ids[count.index]
  }

  block_device {
    uuid                  = var.images.ubuntu.id
    source_type           = "image"
    volume_size           = 20
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }
}
