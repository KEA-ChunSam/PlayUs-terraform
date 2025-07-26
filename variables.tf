variable "region" {
  description = "카카오클라우드 리전"
  type        = string
}

variable "auth_url" {
  description = "OpenStack 인증 URL"
  type        = string
}

variable "credential_id" {
  description = "IAM Application Credential ID"
  type        = string
}

variable "credential_secret" {
  description = "IAM Application Credential Secret"
  type        = string
}

variable "ssh_key_name" {
  description = "SSH 키페어 이름"
  type        = string
}

variable "environment" {
  description = "배포 환경 (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# 네트워크 설정
variable "public_network_id" {
  description = "퍼블릭 네트워크 ID"
  type        = string
}

variable "public_subnet_id" {
  description = "퍼블릭 서브넷 ID"
  type        = string
}

variable "public_subnet_cidr" {
  description = "퍼블릭 서브넷 CIDR"
  type        = string
}

variable "private_subnet_id" {
  description = "프라이빗 서브넷 ID"
  type        = string
}

variable "private_subnet_cidr" {
  description = "프라이빗 서브넷 CIDR"
  type        = string
}

variable "private_subnet_router_id" {
  description = "프라이빗 서브넷 라우터 ID"
  type        = string
}

variable "prefix" {
  description = "리소스 이름 접두사"
  type        = string
  default     = "playus"
}

# 인스턴스 타입 설정 
variable "instance_types" {
  description = "인스턴스 타입 설정"
  type = object({
    bastion    = object({ id = string })
    web        = object({ id = string })
    nat        = object({ id = string })
    k8s_master = object({ id = string })
    k8s_worker = object({ id = string })
  })
  default = {
    # 최적화 설정
    bastion = {
      name = "t1i.medium"
      id   = "1a225644-8411-4277-b44a-00487d575620" # 2vCPU, 4GB RAM 
    }
    nat = {
      name = "t1i.micro"
      id   = "8adaa6de-c42a-40b8-bc55-3cb36d8d8829" # 2vCPU, 1GB RAM 
    }
    web = {
      name = "t1i.medium"
      id   = "1a225644-8411-4277-b44a-00487d575620" # 2vCPU, 4GB RAM
    }
    k8s_master = {
      name = "t1i.medium"
      id   = "1a225644-8411-4277-b44a-00487d575620" # 2vCPU, 4GB RAM 
    }
    k8s_worker = {
      name = "t1i.medium"
      id   = "1a225644-8411-4277-b44a-00487d575620" # 2vCPU, 4GB RAM 
    }
  }
}

# 이미지 설정
variable "images" {
  description = "OS 이미지 설정"
  type = object({
    ubuntu = object({
      name = string
      id   = string
    })
  })
  default = {
    ubuntu = {
      name = "Ubuntu 22.04"
      id   = "07b05fb9-e0e4-4713-b699-5a492ebc7890"
    }
  }
}

variable "alb" {
  description = "ALB 설정"
  type = object({
    flavor_id     = string
    listener_port = number
    health_check = object({
      delay          = number
      timeout        = number
      max_retries    = number
      url_path       = string
      expected_codes = string
    })
  })
  default = {
    flavor_id     = "687c7076-7756-4906-9630-dd51abd6f1e7"
    listener_port = 80
    health_check = {
      delay          = 10
      timeout        = 3
      max_retries    = 3
      url_path       = "/"
      expected_codes = "200"
    }
  }
}

# S3 설정
variable "s3_bucket_name" {
  description = "S3 스토리지 버킷 이름"
  type        = string
  default     = "playus-private-bucket"
}
