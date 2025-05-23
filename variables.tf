# 기본 설정
variable "region" {
  description = "카카오 클라우드 리전"
  type        = string
}

variable "auth_url" {
  description = "OpenStack 인증 URL"
  type        = string
}

variable "application_credential_id" {
  description = "IAM Application Credential ID"
  type        = string
}

variable "application_credential_secret" {
  description = "IAM Application Credential Secret"
  type        = string
}

variable "ssh_key_name" {
  description = "SSH 키페어 이름"
  type        = string
}

# 네트워크 설정
variable "public_subnet_id" {
  description = "퍼블릭 서브넷 ID"
  type        = string
}

variable "public_subnet_network_id" {
  description = "퍼블릭 서브넷이 속한 네트워크 ID"
  type        = string
}

variable "public_network_cidr" {
  description = "퍼블릭 네트워크 CIDR"
  type        = string
}

variable "private_subnet_id" {
  description = "프라이빗 서브넷 ID"
  type        = string
}

variable "private_network_cidr" {
  description = "프라이빗 네트워크 CIDR"
  type        = string
}

# 리소스 이름 접두사
variable "prefix" {
  description = "리소스 이름 접두사"
  type        = string
  default     = "playus"
}

# 이미지 ID
variable "default_image_id" {
  description = "기본 OS 이미지 ID (Ubuntu 20.04)"
  type        = string
  default     = "044eae16-ecc2-4f74-9345-5a9fe90d80a9"
}

# 인스턴스 설정
variable "bastion_flavor" {
  description = "Bastion 인스턴스 flavor"
  type        = string
  default     = "8adaa6de-c42a-40b8-bc55-3cb36d8d8829"  # t1i.micro (2vCPU, 1GB RAM)
}

variable "nat_flavor" {
  description = "NAT 인스턴스 flavor"
  type        = string
  default     = "8adaa6de-c42a-40b8-bc55-3cb36d8d8829"  # t1i.micro (2vCPU, 1GB RAM)
}

variable "web_flavor" {
  description = "Web Server 인스턴스 flavor"
  type        = string
  default     = "1a225644-8411-4277-b44a-00487d575620"  # t1i.medium (2vCPU, 4GB RAM)
}

variable "k8s_master_flavor" {
  description = "k8s 마스터 인스턴스 flavor"
  type        = string
  default     = "1a225644-8411-4277-b44a-00487d575620"  # t1i.medium (2vCPU, 4GB RAM)
}

variable "k8s_slave_flavor" {
  description = "k8s 슬레이브 인스턴스 flavor"
  type        = string
  default     = "1a225644-8411-4277-b44a-00487d575620"  # t1i.medium (2vCPU, 4GB RAM)
}

# ALB 설정
variable "alb_listener_port" {
  description = "ALB 리스너 포트"
  type        = number
  default     = 80
}

# S3 설정
variable "s3_bucket_name" {
  description = "S3 스토리지 버킷 이름"
  type        = string
  default     = "playus-private-bucket"
}
