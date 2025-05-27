# ALB (Application Load Balancer)
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

# HTTP 리스너 (웹 애플리케이션용)
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

# FastAPI 리스너 (8000번 포트)
resource "openstack_lb_listener_v2" "alb_fastapi" {
  name            = "${var.prefix}-alb-fastapi-listener"
  protocol        = "HTTP"
  protocol_port   = 8000
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

# FastAPI 서버 풀
resource "openstack_lb_pool_v2" "alb_fastapi_pool" {
  name        = "${var.prefix}-fastapi-pool"
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.alb_fastapi.id

  timeouts {
    create = "60m"
    update = "60m"
    delete = "30m"
  }
  depends_on = [openstack_lb_listener_v2.alb_fastapi]
}

# 웹 서버 멤버 (80번 포트)
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

# FastAPI 서버 멤버 (8000번 포트)
resource "openstack_lb_member_v2" "fastapi" {
  count         = 1
  pool_id       = openstack_lb_pool_v2.alb_fastapi_pool.id
  address       = openstack_networking_port_v2.web_port.all_fixed_ips[0]
  protocol_port = 8000
  subnet_id     = var.private_subnet_id
  
  timeouts {
    create = "60m"
    update = "60m"
    delete = "30m"
  }
  depends_on = [openstack_lb_pool_v2.alb_fastapi_pool]
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

# FastAPI 서버 헬스 체크
resource "openstack_lb_monitor_v2" "alb_fastapi_monitor" {
  pool_id        = openstack_lb_pool_v2.alb_fastapi_pool.id
  type           = "HTTP"
  delay          = var.alb.health_check.delay
  timeout        = var.alb.health_check.timeout
  max_retries    = var.alb.health_check.max_retries
  http_method    = "GET"
  url_path       = "/health"
  expected_codes = "200"
  depends_on     = [openstack_lb_pool_v2.alb_fastapi_pool]
}

# VIP 포트 생성
resource "openstack_networking_port_v2" "alb_vip_port" {
  name           = "${var.prefix}-alb-vip-port"
  network_id     = var.public_subnet_network_id
  fixed_ip {
    subnet_id = var.public_subnet_id
  }
  security_group_ids = [openstack_networking_secgroup_v2.alb_sg.id]
}
