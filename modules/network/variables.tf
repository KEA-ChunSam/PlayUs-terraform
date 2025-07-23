variable "prefix" {
  description = "리소스 이름 접두사"
  type        = string
}

variable "public_subnet_id" {
  description = "Public 서브넷 ID"
  type        = string
}

variable "private_subnet_id" {
  description = "Private 서브넷 ID"
  type        = string
}

variable "bastion_security_group_id" {
  description = "Bastion 보안 그룹 ID"
  type        = string
}

variable "nat_security_group_id" {
  description = "NAT 보안 그룹 ID"
  type        = string
}

variable "web_security_group_id" {
  description = "Web 보안 그룹 ID"
  type        = string
}

variable "k8s_security_group_id" {
  description = "Kubernetes 보안 그룹 ID"
  type        = string
}
