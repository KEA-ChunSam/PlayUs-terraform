# PlayUs Terraform Infrastructure

카카오 클라우드에서 PlayUs 애플리케이션을 위한 인프라를 구축하는 Terraform Repository입니다.

## 📋 구성 요소

### 🌐 네트워크
- **Public Subnet**: Bastion, NAT Gateway, ALB
- **Private Subnet**: Web Server, Kubernetes Cluster

### 🖥️ 서버 인스턴스
- **Bastion Server**: SSH 접근 및 포트 포워딩 (Nginx Proxy Manager)
- **Web Server**: React 앱
- **NAT Gateway**: Private 서브넷 아웃바운드 트래픽
- **Kubernetes Cluster**: Master 1대 + Worker 2대

### ⚖️ Load Balancer
- **ALB**: 80번 포트
- **Health Check**: 자동 헬스 체크 및 장애 조치

## 🚀 배포 가이드

### 1. 사전 준비

#### 카카오 클라우드 설정
1. [카카오 클라우드 콘솔](https://console.kakaocloud.com)에서 프로젝트 생성
2. IAM > Application Credential 생성
3. VPC > 네트워크 생성 (Public/Private 서브넷)
4. Key Pair 생성

#### 필수 도구 설치
```bash
# Terraform 설치 (1.0 이상)
brew install terraform

# 또는 직접 다운로드
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
```

### 2. 설정 파일 준비

```bash
# 저장소 클론
git clone https://github.com/KEA-ChunSam/PlayUs-terraform.git
cd PlayUs-terraform

# 설정 파일 복사 및 수정
cp terraform.tfvars.example terraform.tfvars
```

#### terraform.tfvars 설정
```hcl
# 기본 설정
# 기본 설정
region  = "kr-central-2"
auth_url = "https://iam.kakaocloud.com/identity/v3"

# 카카오 클라우드 IAM Application Credential
application_credential_id = "your-application-credential-id"
application_credential_secret = "your-application-credential-secret"

# SSH 키페어 이름
ssh_key_name = "your-ssh-key-name"
environment = "dev"

# 네트워크 설정 (카카오 클라우드 콘솔에서 확인)
public_subnet_id = "your-public-subnet-id"
public_subnet_network_id = "your-public-network-id"
public_network_cidr = "10.10.0.0/20"

private_subnet_id = "your-private-subnet-id"
private_network_cidr = "10.10.16.0/20"
router_id = "your-router-id"

# ALB VIP 포트 ID
alb_vip_port_id = "your-alb-vip-port-id"

# 리소스 이름 접두사 (선택사항)
# prefix = "playus" 
```

### 3. 인프라 배포

```bash
# Terraform 초기화
terraform init

# 배포 계획 확인
terraform plan

# 인프라 배포 (약 90분 소요)
terraform apply
```

### 4. 배포 완료 후 접속 정보

```bash
# 배포 완료 후 출력되는 정보
terraform output
```

## 🔐 접속 방법

### SSH 접속
```bash
# Bastion 서버 직접 접속
ssh ubuntu@<bastion-floating-ip>

# 웹 서버 접속 
ssh -p 10000 ubuntu@<bastion-floating-ip>

# K8s Master 접속
ssh -p 10001 ubuntu@<bastion-floating-ip>

# K8s Worker Node 1 접속
ssh -p 10002 ubuntu@<bastion-floating-ip>

# K8s Worker Node 2 접속
ssh -p 10003 ubuntu@<bastion-floating-ip>
```

### 웹 서비스 접속
```bash
# React 웹 애플리케이션
http://<alb-floating-ip>

# Bastion Nginx Proxy Manager (관리용)
http://<bastion-floating-ip>:81
```

## 🛡️ 보안 그룹 구성

### Bastion Server (`playus-bastion-sg`)

| 방향       | 프로토콜/포트         | 출발지           | 설명                                      |
|------------|------------------------|------------------|-------------------------------------------|
| 인바운드   | TCP 22                 | 0.0.0.0/0        | SSH 접속 허용                             |
| 인바운드   | TCP 80                 | 0.0.0.0/0        | Nginx Proxy Manager - HTTP 접속           |
| 인바운드   | TCP 443                | 0.0.0.0/0        | Nginx Proxy Manager - HTTPS 접속          |
| 인바운드   | TCP 81                 | 0.0.0.0/0        | Nginx Proxy Manager - 관리자 페이지 접속   |
| 인바운드   | TCP 10000–10003        | 0.0.0.0/0        | 내부 서버 포트 포워딩 (Web, K8s 등)       |
| 인바운드   | ICMP                   | 0.0.0.0/0        | Ping 테스트 허용                          |
| 아웃바운드 | All                    | 0.0.0.0/0        | 모든 외부 통신 허용                       |

---

### Web Server (`playus-web-sg`)

| 방향       | 프로토콜/포트         | 출발지             | 설명                                       |
|------------|------------------------|--------------------|--------------------------------------------|
| 인바운드   | TCP 22                 | Bastion SG         | Bastion → Web SSH 접속                    |
| 인바운드   | TCP 80                 | ALB SG             | ALB → Web HTTP 요청 허용                  |
| 인바운드   | ICMP                   | Bastion, ALB, K8s SG | 네트워크 진단용 Ping 허용                 |
| 아웃바운드 | All                    | 0.0.0.0/0          | 외부 API 호출 포함 모든 트래픽 허용       |

---

### Application Load Balancer (`playus-alb-sg`)

| 방향       | 프로토콜/포트         | 출발지    | 설명                                |
|------------|------------------------|-----------|-------------------------------------|
| 인바운드   | TCP 80                 | 0.0.0.0/0 | 외부 HTTP 요청 허용                 |
| 인바운드   | TCP 443                | 0.0.0.0/0 | 외부 HTTPS 요청 허용                |
| 인바운드   | ICMP                   | 0.0.0.0/0 | 네트워크 상태 진단용 Ping 허용      |
| 아웃바운드 | All                    | 0.0.0.0/0 | 백엔드 대상에 대한 모든 트래픽 허용 |

---

### Kubernetes Cluster (`playus-k8s-sg`)

| 방향       | 프로토콜/포트         | 출발지             | 설명                                           |
|------------|------------------------|--------------------|------------------------------------------------|
| 인바운드   | TCP 22                 | Bastion SG         | Bastion → K8s SSH                             |
| 인바운드   | TCP 6443               | Bastion, Web SG    | K8s API Server 접근 허용                      |
| 인바운드   | TCP 80                 | 0.0.0.0/0          | Kong Ingress LoadBalancer용 HTTP 요청 허용   |
| 인바운드   | TCP 1024–65535         | K8s SG             | K8s 노드 간 내부 통신                         |
| 인바운드   | ICMP                   | Bastion, Web, K8s SG | 네트워크 상태 진단용 Ping 허용               |
| 아웃바운드 | All                    | 0.0.0.0/0          | Pod, Kong, DNS 등 외부 통신 허용             |

> ❌ NodePort(30000–32767) 규칙은 현재 Terraform에 **포함되지 않음** — 필요 시 추가 가능

---

### NAT Gateway (`playus-nat-sg`)

| 방향       | 프로토콜/포트         | 출발지              | 설명                                  |
|------------|------------------------|---------------------|---------------------------------------|
| 인바운드   | TCP 22                 | Bastion SG          | Bastion → NAT SSH                     |
| 인바운드   | All                    | Private CIDR 대역   | 사설망 → NAT 경유 트래픽 허용        |
| 아웃바운드 | All                    | 0.0.0.0/0           | NAT를 통한 외부 인터넷 통신 허용     |

## 🔄 운영 가이드

### 백업 및 복구
```bash
# 웹 서버 백업 확인
ssh -p 10000 ubuntu@<bastion-ip> 'ls -la /var/www/backups/'

# 수동 롤백 (필요시)
ssh -p 10000 ubuntu@<bastion-ip> 'sudo cp -r /var/www/backups/backup_YYYYMMDD_HHMMSS/* /var/www/html/'
```

### 로그 확인
```bash
# 웹 서버 Nginx 로그
ssh -p 10000 ubuntu@<bastion-ip> 'sudo tail -f /var/log/nginx/access.log'

# 시스템 로그
ssh -p 10000 ubuntu@<bastion-ip> 'sudo journalctl -f'
```

## 🧹 정리

### 인프라 삭제
```bash
# 모든 리소스 삭제
terraform destroy

# 특정 리소스만 삭제
terraform destroy -target=resource_type.resource_name
```
