## PlayUs Terraform Infrastructure

카카오 클라우드에서 PlayUs 애플리케이션을 위한 인프라를 구축하는 Terraform Repository입니다.

<br>

### 📋 구성 요소

#### 네트워크
- **Public Subnet**: Bastion, NAT 인스턴스, ALB
- **Private Subnet**: Web Server, Kubernetes Cluster

#### 서버
- **Bastion Server**: SSH 접근 및 포트 포워딩 (Nginx Proxy Manager)
- **NAT 인스턴스**: Private 서브넷 아웃바운드 트래픽
- **Web Server**: React
- **Kubernetes Cluster**: Master 1대 + Worker 2대

#### 로드 밸런서 
- **포트**: 80
- **라우팅**:

```
사용자 → ALB
        ├── /         → Web (정적 리소스)
        └── /api/*    → K8s (Spring API via Kong)
```

<br>

### 🚀 배포 가이드

#### 1. 사전 준비

- 카카오 클라우드 콘솔에서 프로젝트, VPC, Key Pair, Application Credential 생성
- Terraform 설치 

```bash
brew install terraform
```

#### 2. 설정 파일 준비

```bash
git clone https://github.com/KEA-ChunSam/PlayUs-terraform.git
cd PlayUs-terraform

cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars 수정
```

#### 3. 인프라 배포

```bash
# Terraform 초기화
terraform init

# 배포 계획 확인
terraform plan

# 인프라 배포
terraform apply
```

#### 4. 배포 완료 후 출력 확인

```bash
terraform output
```

<br>

### 🖥️ 접속 정보

#### SSH
```bash
# Bastion
ssh ubuntu@<bastion-floating-ip>

# Web Server
ssh -p 10000 ubuntu@<bastion-floating-ip>

# K8s Master/Workers
ssh -p 10001 ubuntu@<bastion-floating-ip>
ssh -p 10002 ubuntu@<bastion-floating-ip>
ssh -p 10003 ubuntu@<bastion-floating-ip>
```

#### 웹 접속
- React 웹: http://<alb-ip>
- Nginx Proxy Manager: http://<bastion-ip>:81

<br>

### 🔐 보안 그룹 요약

**ALB**
- In: HTTP(80), HTTPS(443), Ping (외부)
- Out: All (→ Web 또는 Kong)

**Bastion**
- In: SSH(22), HTTP(80), HTTPS(443), Admin(81), 포트포워딩(10000–10003), Ping
- Out: All

**NAT**
- In: SSH(from Bastion), Private Subnet 트래픽
- Out: All (SNAT)

**Web**
- In: SSH(from Bastion), HTTP(from ALB), Ping
- Out: All (외부 API 호출 포함)

**Kubernetes**
- In: SSH(from Bastion), API(6443), HTTP(80), 내부통신(1024–65535), Ping
- Out: All
- (NodePort는 현재 미허용)

<br>

### 🧹 인프라 정리

```bash
# 전체 삭제
terraform destroy

# 특정 리소스만 삭제
terraform destroy -target=resource_type.resource_name
```
