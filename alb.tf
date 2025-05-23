# ALB (Application Load Balancer)
resource "openstack_lb_loadbalancer_v2" "alb" {
  name              = "${var.prefix}-alb-2"
  vip_subnet_id     = var.public_subnet_id
  admin_state_up    = true
  availability_zone = "kr-central-2-a"
  flavor_id         = "687c7076-7756-4906-9630-dd51abd6f1e7"  # ALB flavor ID
  
  timeouts {
    create = "90m"
  }
}

resource "openstack_lb_listener_v2" "alb_http" {
  name            = "${var.prefix}-alb-listener"
  protocol        = "HTTP"
  protocol_port   = var.alb_listener_port
  loadbalancer_id = openstack_lb_loadbalancer_v2.alb.id

  timeouts {
    create = "60m"
    update = "60m"
    delete = "30m"
  }
}

resource "openstack_lb_listener_v2" "alb_https" {
  name            = "${var.prefix}-alb-https-listener"
  protocol        = "HTTPS"
  protocol_port   = 443
  loadbalancer_id = openstack_lb_loadbalancer_v2.alb.id
  
  timeouts {
    create = "60m"
    update = "60m"
    delete = "30m"
  }
}

resource "openstack_lb_pool_v2" "alb_web_pool" {
  name        = "${var.prefix}-web-pool"
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.alb_http.id

  timeouts {
    create = "60m"
    update = "60m"
    delete = "30m"
  }
}

resource "openstack_lb_pool_v2" "alb_https_pool" {
  name        = "${var.prefix}-https-pool"
  protocol    = "HTTPS"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.alb_https.id
  
  timeouts {
    create = "60m"
    update = "60m"
    delete = "30m"
  }
}

resource "openstack_lb_member_v2" "web" {
  count         = 1
  pool_id       = openstack_lb_pool_v2.alb_web_pool.id
  address       = openstack_networking_port_v2.web_port.all_fixed_ips[0]
  protocol_port = 80
  subnet_id     = var.private_subnet_id
  
  timeouts {
    create = "60m"
    update = "60m"
    delete = "30m"
  }
}

resource "openstack_lb_member_v2" "k8s_master" {
  pool_id       = openstack_lb_pool_v2.alb_web_pool.id
  address       = openstack_networking_port_v2.k8s_master_port.all_fixed_ips[0]
  protocol_port = 80
  subnet_id     = var.private_subnet_id
}

resource "openstack_lb_member_v2" "k8s_slaves" {
  count         = 2
  pool_id       = openstack_lb_pool_v2.alb_web_pool.id
  address       = element(openstack_networking_port_v2.k8s_slave_port.*.all_fixed_ips[0], count.index)
  protocol_port = 80
  subnet_id     = var.private_subnet_id
}

# ALB Floating IP
resource "openstack_networking_floatingip_v2" "alb_fip" {
  pool = data.openstack_networking_network_v2.floating_network.name
}

resource "openstack_networking_floatingip_associate_v2" "alb_fip_assoc" {
  floating_ip = openstack_networking_floatingip_v2.alb_fip.address
  port_id     = openstack_lb_loadbalancer_v2.alb.vip_port_id
}
