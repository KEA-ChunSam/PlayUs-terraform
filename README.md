# PlayUs Terraform Infrastructure

카카오 클라우드에서 PlayUs 애플리케이션을 위한 인프라를 구축하는 Terraform Repository입니다.

## 🏗️ 인프라 아키텍처

```
┌─────────────────────────────────────────────────────────────────┐
│                        Public Subnet                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Bastion   │  │     NAT     │  │          ALB            │  │
│  │   Server    │  │  Gateway    │  │  ┌─────────┬─────────┐  │  │
│  │             │  │             │  │  │Port 80  │Port 8000│  │  │
│  │ Port Fwd:   │  │             │  │  │Web App  │FastAPI  │  │  │
│  │ 10000-10003 │  │             │  │  └─────────┴─────────┘  │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────────┐
│                       Private Subnet                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┬─────────────┐│
│  │ Web Server  │  │ K8s Master  │  │K8s Slave 1  │K8s Slave 2  ││
│  │             │  │             │  │             │             ││
│  │ - Nginx     │  │ - API Server│  │ - Worker    │ - Worker    ││
│  │ - React App │  │ - etcd      │  │ - Pods      │ - Pods      ││
│  │             │  │ - Scheduler │  │             │             ││
│  └─────────────┘  └─────────────┘  └─────────────┴─────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

## 📋 구성 요소

### 🌐 네트워크
- **Public Subnet**: Bastion, NAT Gateway, ALB
- **Private Subnet**: Web Server, Kubernetes Cluster
- **Security Groups**: 각 서비스별 최소 권한 원칙 적용

### 🖥️ 서버 인스턴스
- **Bastion Server**: SSH 접근 및 포트 포워딩 (Nginx Proxy Manager)
- **Web Server**: React 앱
- **NAT Gateway**: Private 서브넷 아웃바운드 트래픽
- **Kubernetes Cluster**: Master 1대 + Worker 2대

### ⚖️ Load Balancer
- **ALB**: 80번 포트(웹앱), 8000번 포트(FastAPI)
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
git clone <repository-url>
cd PlayUs-terraform

# 설정 파일 복사 및 수정
cp terraform.tfvars.example terraform.tfvars
```

#### terraform.tfvars 설정
```hcl
# 기본 설정
region  = "kr-central-2"
auth_url = "https://iam.kakaocloud.com/identity/v3"

# IAM Credential (카카오 클라우드 콘솔에서 생성)
application_credential_id = "your-credential-id"
application_credential_secret = "your-credential-secret"

# SSH 키페어 (카카오 클라우드 콘솔에서 생성한 키 이름)
ssh_key_name = "your-ssh-key-name"
environment = "dev"

# 네트워크 설정 (카카오 클라우드 콘솔에서 확인)
public_subnet_id            = "your-public-subnet-id"
public_subnet_network_id    = "your-public-network-id"
public_network_cidr         = "10.10.0.0/20"

private_subnet_id        = "your-private-subnet-id"
private_network_cidr     = "10.10.16.0/20"
router_id               = "your-router-id"
```

### 3. 인프라 배포

```bash
# Terraform 초기화
terraform init

# 배포 계획 확인
terraform plan

# 인프라 배포 (약 10-15분 소요)
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

# 웹 서버 접속 (포트 포워딩)
ssh -p 10000 ubuntu@<bastion-floating-ip>

# K8s Master 접속
ssh -p 10001 ubuntu@<bastion-floating-ip>

# K8s Slave 1 접속
ssh -p 10002 ubuntu@<bastion-floating-ip>

# K8s Slave 2 접속
ssh -p 10003 ubuntu@<bastion-floating-ip>
```

### 웹 서비스 접속
```bash
# React 웹 애플리케이션
http://<alb-floating-ip>

# FastAPI 서버
http://<alb-floating-ip>:8000

# Bastion Nginx Proxy Manager (관리용)
http://<bastion-floating-ip>:81
```

## 🔧 CI/CD 설정

### GitHub Actions 설정
1. GitHub 저장소의 Settings > Secrets에 다음 값들 추가:

```yaml
# 필수 Secrets
BASTION_HOST: <bastion-floating-ip>
BASTION_USER: ubuntu
BASTION_KEY: <private-key-content>
REACT_DEVELOP_JSON: <react-env-variables-json>
SLACK_WEBHOOK_URL: <slack-webhook-url> (선택사항)
APP_URL: http://<alb-floating-ip> (선택사항)
```

2. React 환경 변수 JSON 예시:
```json
{
  "REACT_APP_API_URL": "http://your-alb-ip",
  "REACT_APP_PROFANITY_DETECT_API_BASE": "http://your-alb-ip:8000/detect",
  "NODE_ENV": "development"
}
```

### 자동 배포
- `develop` 브랜치에 push 시 자동 배포
- 빌드 → 테스트 → 배포 → 헬스체크 → 알림

## 🛡️ 보안 그룹 구성

### Bastion Server
- **인바운드**: SSH(22), HTTP(80), HTTPS(443), Admin(81), Port Forwarding(10000-10003)
- **아웃바운드**: 모든 트래픽

### Web Server
- **인바운드**: SSH(Bastion), HTTP(ALB), FastAPI(ALB), K8s API(8080)
- **아웃바운드**: 모든 트래픽

### ALB
- **인바운드**: HTTP(80), HTTPS(443), FastAPI(8000)
- **아웃바운드**: 모든 트래픽

### Kubernetes Cluster
- **인바운드**: SSH(Bastion), API(6443), NodePort(30000-32767), 내부 통신
- **아웃바운드**: 모든 트래픽

### NAT Gateway
- **인바운드**: SSH(Bastion), Private 서브넷 모든 트래픽
- **아웃바운드**: 모든 트래픽

## 📊 리소스 사양

| 서버 | 인스턴스 타입 | vCPU | RAM | 디스크 |
|------|---------------|------|-----|--------|
| Bastion | t1i.micro | 2 | 1GB | 20GB |
| Web | t1i.medium | 2 | 4GB | 20GB |
| NAT | t1i.micro | 2 | 1GB | 20GB |
| K8s Master | t1i.medium | 2 | 4GB | 20GB |
| K8s Slave | t1i.medium | 2 | 4GB | 20GB |

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

### 모니터링
```bash
# 서버 상태 확인
ssh -p 10000 ubuntu@<bastion-ip> 'systemctl status nginx'

# ALB 헬스 체크 확인
curl -I http://<alb-floating-ip>/
curl -I http://<alb-floating-ip>:8000/health
```

## 🧹 정리

### 인프라 삭제
```bash
# 모든 리소스 삭제
terraform destroy

# 특정 리소스만 삭제
terraform destroy -target=resource_type.resource_name
```

### 주의사항
- 삭제 전 중요 데이터 백업 필수
- S3 버킷 내용은 수동으로 삭제 필요
- Floating IP는 별도로 해제 필요할 수 있음

## 🐛 트러블슈팅

### 일반적인 문제들

#### 1. Terraform 초기화 실패
```bash
# 캐시 삭제 후 재시도
rm -rf .terraform
terraform init
```

#### 2. 인스턴스 생성 실패
- 할당량 확인: 카카오 클라우드 콘솔에서 리소스 할당량 확인
- 이미지 ID 확인: 최신 Ubuntu 20.04 이미지 ID 확인

#### 3. 네트워크 연결 문제
- 보안 그룹 규칙 확인
- 라우팅 테이블 확인
- NAT Gateway 상태 확인

#### 4. 배포 실패
```bash
# SSH 연결 테스트
ssh -p 10000 ubuntu@<bastion-ip> 'echo "Connection OK"'

# Nginx 상태 확인
ssh -p 10000 ubuntu@<bastion-ip> 'sudo systemctl status nginx'
```

