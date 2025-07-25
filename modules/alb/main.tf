terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = ">= 1.40.0"
    }
  }
}

# ALB VIP 포트 생성
resource "openstack_networking_port_v2" "alb_vip_port" {
  name           = "${var.prefix}-alb-vip-port"
  network_id     = var.public_network_id
  admin_state_up = true

  fixed_ip {
    subnet_id = var.public_subnet_id
  }

  security_group_ids = [
    var.alb_security_group_id
  ]
}

resource "openstack_lb_loadbalancer_v2" "alb" {
  name              = "${var.prefix}-alb"
  vip_port_id       = openstack_networking_port_v2.alb_vip_port.id
  admin_state_up    = true
  availability_zone = "kr-central-2-a"
  flavor_id         = var.alb.flavor_id

  timeouts {
    create = "90m"
  }

  depends_on = [openstack_networking_port_v2.alb_vip_port]
}

# ALB Floating IP
resource "openstack_networking_floatingip_v2" "alb_fip" {
  pool = var.floating_network_name
}

# ALB Floating IP 연결
resource "openstack_networking_floatingip_associate_v2" "alb_fip_assoc" {
  floating_ip = openstack_networking_floatingip_v2.alb_fip.address
  port_id     = openstack_lb_loadbalancer_v2.alb.vip_port_id
  depends_on  = [openstack_lb_loadbalancer_v2.alb]
}

# HTTP 리스너 
resource "openstack_lb_listener_v2" "alb_http" {
  name            = "${var.prefix}-alb-http-listener"
  protocol        = "HTTP"
  protocol_port   = 80
  loadbalancer_id = openstack_lb_loadbalancer_v2.alb.id

  timeouts {
    create = "60m"
    update = "60m"
    delete = "30m"
  }

  depends_on = [openstack_lb_loadbalancer_v2.alb]
}

# 웹 애플리케이션 풀
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

# 웹 서버 멤버 (80번 포트)
resource "openstack_lb_member_v2" "web" {
  count         = 1
  pool_id       = openstack_lb_pool_v2.alb_web_pool.id
  address       = var.web_server_private_ip
  protocol_port = 80
  subnet_id     = var.private_subnet_id

  timeouts {
    create = "60m"
    update = "60m"
    delete = "30m"
  }

  depends_on = [openstack_lb_pool_v2.alb_web_pool]
}

# 웹 애플리케이션 헬스 체크
resource "openstack_lb_monitor_v2" "alb_web_monitor" {
  pool_id        = openstack_lb_pool_v2.alb_web_pool.id
  type           = "HTTP"
  delay          = var.alb.health_check.delay
  timeout        = var.alb.health_check.timeout
  max_retries    = var.alb.health_check.max_retries
  http_method    = "GET"
  url_path       = "/"
  expected_codes = "200"
  depends_on     = [openstack_lb_pool_v2.alb_web_pool]
}
