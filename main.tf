# SSH Keypair 정보 가져오기
data "openstack_compute_keypair_v2" "ssh_key" {
  name = var.ssh_key_name
}

# Security 모듈
module "security" {
  source = "./modules/security"

  prefix              = var.prefix
  environment         = var.environment
  private_subnet_cidr = var.private_subnet_cidr
}

# Network 모듈
module "network" {
  source = "./modules/network"

  prefix                    = var.prefix
  public_subnet_id          = var.public_subnet_id
  private_subnet_id         = var.private_subnet_id

  bastion_security_group_id = module.security.bastion_security_group_id
  nat_security_group_id     = module.security.nat_security_group_id
  web_security_group_id     = module.security.web_security_group_id
  k8s_security_group_id     = module.security.k8s_security_group_id

  depends_on = [module.security]
}

# Compute 모듈
module "compute" {
  source = "./modules/compute"

  prefix             = var.prefix
  ssh_key_name       = var.ssh_key_name
  images             = var.images
  instance_types     = var.instance_types
  bastion_port_id    = module.network.bastion_port_id
  web_port_id        = module.network.web_port_id
  nat_port_id        = module.network.nat_port_id
  k8s_master_port_id = module.network.k8s_master_port_id
  k8s_slave_port_ids = module.network.k8s_slave_port_ids

  depends_on = [module.network]
}

# ALB 모듈
module "alb" {
  source = "./modules/alb"

  prefix = var.prefix

  public_network_id = var.public_network_id
  public_subnet_id  = var.public_subnet_id

  private_subnet_id     = var.private_subnet_id
  alb_security_group_id = module.security.alb_security_group_id
  web_server_private_ip = module.network.web_port_private_ip
  floating_network_name = module.network.floating_network_name
  alb                   = var.alb

  depends_on = [module.security, module.network]
}

# Storage 모듈
module "storage" {
  source = "./modules/storage"

  s3_bucket_name = var.s3_bucket_name
}

# Floating IP 연결
resource "openstack_networking_floatingip_associate_v2" "bastion_fip_assoc" {
  floating_ip = module.network.bastion_floating_ip
  port_id     = module.network.bastion_port_id
  depends_on  = [module.compute.bastion_instance_id]
}

resource "openstack_networking_floatingip_associate_v2" "nat_fip_assoc" {
  floating_ip = module.network.nat_floating_ip
  port_id     = module.network.nat_port_id
  depends_on  = [module.compute.nat_instance_id]
}

# 라우터 라우트
resource "openstack_networking_router_route_v2" "private_route" {
  router_id        = var.private_subnet_router_id
  destination_cidr = "0.0.0.0/0"
  next_hop         = module.compute.nat_instance_private_ip
  depends_on = [
    module.compute.nat_instance_id,
    openstack_networking_floatingip_associate_v2.nat_fip_assoc
  ]

  lifecycle {
    # 라우터 라우트가 이미 존재하는 경우 충돌 방지
    ignore_changes = [
      next_hop
    ]
  }
}
