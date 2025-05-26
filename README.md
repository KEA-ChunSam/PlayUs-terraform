# PlayUs Terraform Infrastructure

PlayUs 프로젝트를 위한 카카오 클라우드(OpenStack) 인프라 구성 및 CI/CD 파이프라인

## 📋 목차

- [인프라 구성](#인프라-구성)
- [CI/CD 설정](#cicd-설정)
- [배포 방법](#배포-방법)
- [모니터링](#모니터링)
- [트러블슈팅](#트러블슈팅)

## 🏗️ 인프라 구성

### 아키텍처

```
Internet
    |
   ALB (Application Load Balancer)
    |
Web Server (React App)
    |
Bastion Host ---- NAT Gateway
    |                |
k8s Master ---- k8s Slaves
```

### 주요 컴포넌트

- **Bastion Host**: SSH 터널링 및 Nginx Proxy Manager
- **Web Server**: React 애플리케이션 호스팅 (Nginx)
- **ALB**: 로드 밸런서
- **k8s Cluster**: 마스터 1개, 슬레이브 2개
- **NAT Gateway**: 프라이빗 서브넷 아웃바운드 인터넷 접근

## 🚀 CI/CD 설정

### GitHub Secrets 설정

다음 secrets를 GitHub 리포지토리에 설정해야 합니다:

```bash
# SSH 연결 정보
BASTION_HOST=<bastion_public_ip>
BASTION_USER=ubuntu
BASTION_KEY=<private_key_content>
WEB_SERVER=<web_server_private_ip>

# 애플리케이션 설정
APP_URL=<application_public_url>
REACT_DEVELOP_JSON=<react_environment_variables_json>

# 알림 설정 (선택사항)
SLACK_WEBHOOK_URL=<slack_webhook_url>
```

### REACT_DEVELOP_JSON 형식

```json
{
  "REACT_APP_API_URL": "http://your-api-endpoint:8080",
  "REACT_APP_ENVIRONMENT": "development",
  "REACT_APP_FEATURE_FLAG": "true"
}
```

## 📦 배포 방법

### 1. 인프라 배포

```bash
# Terraform 초기화
terraform init

# 계획 확인
terraform plan

# 인프라 배포
terraform apply
```

### 2. 자동 배포 (CI/CD)

`develop` 브랜치에 푸시하면 자동으로 배포됩니다:

```bash
git push origin develop
```

### 3. 수동 배포

```bash
# 웹 서버에 SSH 접속
ssh -J ubuntu@<bastion_ip> ubuntu@<web_server_ip>

# 배포 스크립트 실행
./deploy.sh
```

## 🔧 배포 스크립트

### 배포 프로세스

1. **백업 생성**: 현재 배포된 파일을 백업
2. **파일 전송**: 새로운 빌드 파일을 서버로 전송
3. **배포 적용**: 백업 후 새 파일로 교체
4. **서비스 재시작**: Nginx 재시작
5. **헬스 체크**: 배포 성공 확인

### 롤백

```bash
# 사용 가능한 백업 확인
./rollback.sh

# 특정 백업으로 롤백
./rollback.sh 20241201_143022
```

## 📊 모니터링

### 헬스 체크 엔드포인트

- **내부**: `http://localhost/health`
- **외부**: `http://<app_url>/health`
- **버전 정보**: `http://<app_url>/version.json`

### 로그 확인

```bash
# Nginx 로그
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# 시스템 로그
sudo journalctl -u nginx -f
```

## 🔍 트러블슈팅

### 일반적인 문제

#### 1. SSH 연결 실패

```bash
# known_hosts 초기화
ssh-keygen -R <bastion_ip>
ssh-keygen -R <web_server_ip>

# SSH 키 권한 확인
chmod 600 private_key
```

#### 2. Nginx 설정 오류

```bash
# 설정 테스트
sudo nginx -t

# 설정 파일 확인
sudo nano /etc/nginx/sites-available/frontend
```

#### 3. 권한 문제

```bash
# 웹 디렉토리 권한 수정
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
```

#### 4. 배포 실패

```bash
# 배포 디렉토리 확인
ls -la /home/ubuntu/deploy/

# 수동 배포
sudo cp -r /home/ubuntu/deploy/* /var/www/html/
sudo systemctl restart nginx
```

### 로그 분석

```bash
# CI/CD 로그에서 오류 확인
grep -i error /var/log/nginx/error.log

# 배포 스크립트 로그
tail -f /var/log/syslog | grep deploy
```

## 🛠️ 개발 환경 설정

### 로컬 개발

```bash
# 의존성 설치
npm install

# 개발 서버 실행
npm start

# 테스트 실행
npm test

# 빌드
npm run build
```

### 환경 변수

로컬 개발 시 `.env.local` 파일 생성:

```bash
REACT_APP_API_URL=http://localhost:8080
REACT_APP_ENVIRONMENT=local
```

## 📝 참고사항

- Node.js 18.x 사용
- React 애플리케이션
- Nginx 웹 서버
- Ubuntu 20.04 LTS
- 백업은 7일간 보관
- 배포 시 자동 롤백 기능 포함

## 🤝 기여하기

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 있습니다. 