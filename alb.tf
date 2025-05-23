# ALB (Application Load Balancer)
resource "openstack_lb_loadbalancer_v2" "alb" {
  name              = "${var.prefix}-alb"
  vip_port_id       = openstack_networking_port_v2.alb_vip_port.id
  admin_state_up    = true
  availability_zone = "kr-central-2-a"
  flavor_id         = "687c7076-7756-4906-9630-dd51abd6f1e7"  # ALB flavor ID
  
  timeouts {
    create = "90m"
  }
  depends_on = [openstack_networking_port_v2.alb_vip_port]
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
  depends_on = [openstack_lb_loadbalancer_v2.alb]
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
  depends_on = [openstack_lb_listener_v2.alb_http]
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
  depends_on = [openstack_lb_pool_v2.alb_web_pool]
}

resource "openstack_lb_member_v2" "k8s_master" {
  pool_id       = openstack_lb_pool_v2.alb_web_pool.id
  address       = openstack_networking_port_v2.k8s_master_port.all_fixed_ips[0]
  protocol_port = 80
  subnet_id     = var.private_subnet_id
  depends_on    = [openstack_lb_pool_v2.alb_web_pool]
}

resource "openstack_lb_member_v2" "k8s_slaves" {
  count         = 2
  pool_id       = openstack_lb_pool_v2.alb_web_pool.id
  address       = element(openstack_networking_port_v2.k8s_slave_port.*.all_fixed_ips[0], count.index)
  protocol_port = 80
  subnet_id     = var.private_subnet_id
  depends_on    = [openstack_lb_pool_v2.alb_web_pool]
}

# ALB Floating IP
resource "openstack_networking_floatingip_v2" "alb_fip" {
  pool = data.openstack_networking_network_v2.floating_network.name
}

resource "openstack_networking_floatingip_associate_v2" "alb_fip_assoc" {
  floating_ip = openstack_networking_floatingip_v2.alb_fip.address
  port_id     = openstack_lb_loadbalancer_v2.alb.vip_port_id
  depends_on  = [openstack_lb_loadbalancer_v2.alb]
}

resource "openstack_lb_monitor_v2" "alb_web_monitor" {
  pool_id        = openstack_lb_pool_v2.alb_web_pool.id
  type           = "HTTP"
  delay          = 5
  timeout        = 3
  max_retries    = 3
  http_method    = "GET"
  url_path       = "/"
  expected_codes = "200"
  depends_on     = [openstack_lb_pool_v2.alb_web_pool]
}

# VIP 포트에 보안 그룹 할당
resource "openstack_networking_port_v2" "alb_vip_port" {
  name           = "${var.prefix}-alb-vip-port"
  network_id     = var.public_subnet_network_id
  fixed_ip {
    subnet_id = var.public_subnet_id
  }
  security_group_ids = [openstack_networking_secgroup_v2.alb_sg.id]
}
