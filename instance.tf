resource "openstack_compute_instance_v2" "bastion" {
  name        = "${var.prefix}-bastion"
  image_id    = var.images.ubuntu_20_04.id
  flavor_id   = var.instance_types.bastion.id
  key_pair    = var.ssh_key_name
  user_data   = file("${path.module}/templates/init-bastion.sh")

  network {
    port = openstack_networking_port_v2.bastion_port.id
  }

  block_device {
    uuid                  = var.images.ubuntu_20_04.id
    source_type          = "image"
    volume_size          = 20
    boot_index           = 0
    destination_type     = "volume"
    delete_on_termination = true
  }
}

resource "openstack_compute_instance_v2" "web" {
  name        = "${var.prefix}-web"
  image_id    = var.images.ubuntu_20_04.id
  flavor_id   = var.instance_types.web.id
  key_pair    = var.ssh_key_name
  user_data   = "${local.web_env}\n${local.web_init}"

  network {
    port = openstack_networking_port_v2.web_port.id
  }

  block_device {
    uuid                  = var.images.ubuntu_20_04.id
    source_type          = "image"
    volume_size          = 20
    boot_index           = 0
    destination_type     = "volume"
    delete_on_termination = true
  }
}

resource "openstack_compute_instance_v2" "nat" {
  name        = "${var.prefix}-nat"
  image_id    = var.images.ubuntu_20_04.id
  flavor_id   = var.instance_types.nat.id
  key_pair    = var.ssh_key_name
  user_data   = file("${path.module}/templates/init-nat.sh")

  network {
    port = openstack_networking_port_v2.nat_port.id
  }

  block_device {
    uuid                  = var.images.ubuntu_20_04.id
    source_type          = "image"
    volume_size          = 20
    boot_index           = 0
    destination_type     = "volume"
    delete_on_termination = true
  }
}

resource "openstack_compute_instance_v2" "k8s_master" {
  name        = "${var.prefix}-k8s-master"
  image_id    = var.images.ubuntu_20_04.id
  flavor_id   = var.instance_types.k8s_master.id
  key_pair    = var.ssh_key_name
  user_data   = file("${path.module}/templates/init-k8s-master.sh")

  network {
    port = openstack_networking_port_v2.k8s_master_port.id
  }

  block_device {
    uuid                  = var.images.ubuntu_20_04.id
    source_type          = "image"
    volume_size          = 20
    boot_index           = 0
    destination_type     = "volume"
    delete_on_termination = true
  }
}

resource "openstack_compute_instance_v2" "k8s_slave" {
  count       = 2
  name        = "${var.prefix}-k8s-slave-${count.index + 1}"
  image_id    = var.images.ubuntu_20_04.id
  flavor_id   = var.instance_types.k8s_slave.id
  key_pair    = var.ssh_key_name
  user_data   = file("${path.module}/templates/init-k8s-slave.sh")

  network {
    port = openstack_networking_port_v2.k8s_slave_port[count.index].id
  }

  block_device {
    uuid                  = var.images.ubuntu_20_04.id
    source_type          = "image"
    volume_size          = 20
    boot_index           = 0
    destination_type     = "volume"
    delete_on_termination = true
  }
}
