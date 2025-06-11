<div align="center">
  <img width="80" alt="Logo_REAL" src="https://github.com/user-attachments/assets/3dc13b9c-c793-44e9-9e02-713abeb15d2a" />
  <h1>PlayUs Terraform Infrastructure</h1>
  <p><em>Terraform으로 KakaoCloud 기반의 PlayUs 인프라를 자동화합니다</em></p>
  <p>
    <img src="https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform"/>
    </a>
    <img src="https://img.shields.io/badge/Kakao%20Cloud-FFCD00?style=for-the-badge&logo=icloud&logoColor=black" alt="KakaoCloud"/>
    </a>
    <img src="https://img.shields.io/badge/구축기간-2025.05~06-4CAF50?style=for-the-badge" alt="구축기간"/>
  </p>
</div>

<br>

### 시스템 아키텍처

<br>

![Group 1597880824](https://github.com/user-attachments/assets/00eda314-6152-4506-8af7-352739e15257)


<br>

###  🚀 Quick Start

**1. 사전 준비**

- Kakao Cloud 콘솔에서 리소스 생성
  
  - 프로젝트, VPC, Key Pair, Application Credential

- Terraform 설치

```bash
brew install terraform
```

**2. 설정 파일 구성**

```bash
git clone https://github.com/KEA-ChunSam/PlayUs-terraform.git
cd PlayUs-terraform
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars 파일을 환경에 맞게 수정
```

**3. 인프라 배포**

```bash
terraform init       # 초기화
terraform plan       # 배포 계획 확인
terraform apply      # 실제 인프라 생성
```

**4. 배포 결과 확인**

```bash
terraform output     # Floating IP, VIP 등 출력 확인
```

**5. 리소스 삭제**

```bash
# 전체 인프라 삭제
terraform destroy

# 특정 리소스만 삭제
terraform destroy -target=resource_type.resource_name
```
