variable "prefix" {
  description = "리소스 이름 접두사"
  type        = string
}

variable "public_network_id" {
  description = "퍼블릭 네트워크 ID"
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

variable "alb_security_group_id" {
  description = "ALB 보안 그룹 ID"
  type        = string
}

variable "web_server_private_ip" {
  description = "Web 서버 Private IP"
  type        = string
}

variable "floating_network_name" {
  description = "Floating 네트워크 이름"
  type        = string
}

variable "alb" {
  description = "ALB 설정"
  type = object({
    flavor_id = string
    health_check = object({
      delay       = number
      timeout     = number
      max_retries = number
    })
  })
}
