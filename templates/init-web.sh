#!/bin/bash

# 환경 변수 로드
if [ -f /tmp/web-env ]; then
    source /tmp/web-env
fi

# 로깅 함수
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 에러 처리 함수
handle_error() {
    log "ERROR: $1"
    exit 1
}

# 필수 패키지 설치
log "필수 패키지 설치 중..."
sudo apt-get update
sudo apt-get install -y nginx curl

# 디렉토리 생성 및 권한 설정
log "디렉토리 설정 중..."
WEB_ROOT="/var/www/html"
BACKUP_ROOT="/var/www/backups"
DEPLOY_DIR="/home/ubuntu/deploy"

sudo mkdir -p "$BACKUP_ROOT" "$WEB_ROOT" "$DEPLOY_DIR"
sudo chown -R ubuntu:ubuntu "$BACKUP_ROOT" "$DEPLOY_DIR"
sudo chown -R www-data:www-data "$WEB_ROOT"

# ubuntu 사용자를 www-data 그룹에 추가 (CI/CD 배포를 위해)
sudo usermod -a -G www-data ubuntu

# 배포 디렉토리 권한 설정 (CI/CD에서 접근 가능하도록)
sudo chmod 755 "$DEPLOY_DIR"
sudo chmod 775 "$WEB_ROOT"

# Nginx 설정
log "Nginx 설정 중..."
cat > /tmp/frontend.conf << EOF
server {
    listen 80;
    server_name _;
    root $WEB_ROOT;
    index index.html;

    # 클라이언트 최대 업로드 크기 설정
    client_max_body_size 100M;

    # SPA 라우팅 및 헬스 체크
    location / {
        try_files \$uri \$uri/ /index.html;
        access_log off;
    }

    # 정적 파일 캐싱
    location /static/ {
        expires 1y;
        add_header Cache-Control "public, no-transform";
    }

    # 에러 페이지
    error_page 404 /index.html;
    error_page 500 502 503 504 /50x.html;
    
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
EOF

sudo mv /tmp/frontend.conf /etc/nginx/sites-available/frontend
sudo ln -sf /etc/nginx/sites-available/frontend /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Nginx 설정 테스트 및 시작
log "Nginx 설정 및 시작 중..."
sudo nginx -t || handle_error "Nginx 설정 테스트 실패"
sudo systemctl enable nginx
sudo systemctl start nginx || handle_error "Nginx 시작 실패"

log "웹 서버 초기화 완료"
