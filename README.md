# PlayUs Terraform Infrastructure

카카오 클라우드(KakaoCloud) 기반 PlayUs 프로젝트 인프라 구성

## 📋 목차

- [환경 설정](#환경-설정)
- [인프라 구성](#인프라-구성)
- [배포 방법](#배포-방법)
- [네트워크 구성](#네트워크-구성)
- [모니터링](#모니터링)
- [트러블슈팅](#트러블슈팅)

## 🌐 환경 설정

### 카카오 클라우드 사전 준비

1. **카카오 클라우드 계정 생성**
   - [카카오 클라우드 콘솔](https://console.kakaocloud.com) 접속
   - 계정 생성 및 프로젝트 생성

2. **IAM Application Credential 생성**
   ```bash
   # 카카오 클라우드 콘솔에서 생성
   # IAM > Application Credentials > 새 Credential 생성
   ```

3. **SSH 키페어 생성**
   ```bash
   # 카카오 클라우드 콘솔에서 생성
   # Compute > Key Pairs > 키페어 생성
   # 또는 로컬에서 생성 후 등록
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/playus-key
   ```

4. **네트워크 리소스 확인**
   - VPC, 서브넷, 라우터 ID 확인
   - 퍼블릭/프라이빗 서브넷 CIDR 확인

### Terraform 설치

```bash
# macOS
brew install terraform

# Ubuntu/Debian
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

## 🏗️ 인프라 구성

### 아키텍처

```
Internet
    |
   ALB (Application Load Balancer)
    |
Web Server (React App + FastAPI:8000)
    |
Bastion Host (Nginx Proxy Manager)
    |-- Port 10000 → Web Server:22
    |-- Port 10001 → K8s Master:22
    |-- Port 10002 → K8s Slave1:22
    |-- Port 10003 → K8s Slave2:22
    |
NAT Gateway ← Private Network
    |
k8s Master ← k8s Slave1, k8s Slave2
```

### 주요 컴포넌트

- **Bastion Host**: SSH 터널링 및 Nginx Proxy Manager (포트 포워딩)
- **Web Server**: React 애플리케이션 + FastAPI 서버 (포트 8000)
- **ALB**: 로드 밸런서 (HTTP/HTTPS/API)
- **k8s Cluster**: 마스터 1개, 슬레이브 2개 (containerd 런타임)
- **NAT Gateway**: 프라이빗 서브넷 아웃바운드 인터넷 접근

### 보안 그룹 구성

| 서비스 | 포트 | 소스 | 용도 |
|--------|------|------|------|
| Bastion | 22 | 0.0.0.0/0 | SSH 접근 |
| Bastion | 10000-10003 | 0.0.0.0/0 | 포트 포워딩 |
| Bastion | 80, 443, 81 | 0.0.0.0/0 | Nginx Proxy Manager |
| Web | 22 | Bastion SG | SSH (Bastion을 통해서만) |
| Web | 80 | ALB SG | HTTP (ALB를 통해서만) |
| Web | 8000 | 0.0.0.0/0 | FastAPI (외부 Python 앱) |
| ALB | 80, 443, 8080 | 0.0.0.0/0 | 웹 서비스 |


## 📦 배포 방법


```bash
# 저장소 클론
git clone <repository-url>
cd PlayUs-terraform

# terraform.tfvars 파일 설정
cp terraform.tfvars.example terraform.tfvars
# 카카오 클라우드 정보 입력

# Terraform 초기화
terraform init

# 계획 확인
terraform plan

# 인프라 배포
terraform apply
```



## 🌐 네트워크 구성

### SSH 접근 방법

```bash
# Bastion Host 직접 접근
ssh ubuntu@<bastion_public_ip>

# Web Server 접근 (포트 포워딩)
ssh -p 10000 ubuntu@<bastion_public_ip>

# K8s Master 접근 (포트 포워딩)
ssh -p 10001 ubuntu@<bastion_public_ip>

# K8s Slave1 접근 (포트 포워딩)
ssh -p 10002 ubuntu@<bastion_public_ip>

# K8s Slave2 접근 (포트 포워딩)
ssh -p 10003 ubuntu@<bastion_public_ip>
```

### FastAPI 통신

```python
# 외부 Python 애플리케이션에서 FastAPI 접근
import requests

# 직접 접근 (보안 그룹에서 8000번 포트 허용)
response = requests.get("http://<web_server_public_ip>:8000/api/endpoint")

# Nginx 프록시를 통한 접근
response = requests.get("http://<alb_ip>/fastapi/api/endpoint")
```

### 포트 매핑

| 서비스 | Bastion 포트 | 대상 서버 | 대상 포트 | 용도 |
|--------|-------------|----------|----------|------|
| Web Server | 10000 | Web Server | 22 | SSH 접근 |
| K8s Master | 10001 | K8s Master | 22 | SSH 접근 |
| K8s Slave1 | 10002 | K8s Slave1 | 22 | SSH 접근 |
| K8s Slave2 | 10003 | K8s Slave2 | 22 | SSH 접근 |


## 📊 모니터링

### 헬스 체크 엔드포인트

- **내부**: `http://localhost/health`
- **외부**: `http://<alb_ip>/health`
- **버전 정보**: `http://<alb_ip>/version.json`
- **FastAPI**: `http://<web_server_ip>:8000/docs`

### 로그 확인

```bash
# Nginx 로그
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# 시스템 로그
sudo journalctl -u nginx -f

# Docker 로그 (Bastion - Nginx Proxy Manager)
sudo docker-compose -f ~/nginx-proxy-manager/docker-compose.yaml logs -f
```

### Nginx Proxy Manager 관리

```bash
# 관리 인터페이스 접근
http://<bastion_ip>:81

# 기본 로그인 정보
Email: admin@example.com
Password: changeme
```

## 🔍 트러블슈팅

### 일반적인 문제

#### 1. SSH 연결 실패

```bash
# known_hosts 초기화
ssh-keygen -R <bastion_ip>
ssh-keygen -R "[<bastion_ip>]:10000"

# SSH 키 권한 확인
chmod 600 ~/.ssh/playus-key

# 포트 포워딩 확인
ssh -p 10000 -v ubuntu@<bastion_ip>
```

#### 2. 포트 포워딩 문제

```bash
# Bastion에서 포트 포워딩 상태 확인
sudo docker exec nginx-proxy-manager_app_1 nginx -T

# 포트 리스닝 확인
sudo netstat -tlnp | grep :10000
```

#### 3. 보안 그룹 문제

```bash
# 카카오 클라우드 콘솔에서 보안 그룹 규칙 확인
# Compute > Security Groups > 해당 보안 그룹 선택

# 테라폼으로 보안 그룹 재적용
terraform plan -target=openstack_networking_secgroup_v2.web_sg
terraform apply -target=openstack_networking_secgroup_v2.web_sg
```

### 로그 분석

```bash
# 포트 포워딩 로그
sudo docker logs nginx-proxy-manager_app_1

# 시스템 로그
sudo journalctl -xe
```




### 보안 고려사항

- SSH 접근은 Bastion Host를 통해서만 가능
- 포트 포워딩을 통한 내부 서버 접근
- 보안 그룹을 통한 네트워크 레벨 접근 제어
- FastAPI는 필요한 경우에만 외부 노출
