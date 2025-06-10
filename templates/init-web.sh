#!/bin/bash

# 웹 서버 초기화 스크립트

# 환경 변수 로드
if [ -f /tmp/web-env ]; then
    source /tmp/web-env
fi

# 로그 함수
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

handle_error() {
    log "ERROR: $1"
    exit 1
}

# 필수 패키지
log "필수 패키지 설치 중"
sudo apt-get update
sudo apt-get install -y nginx curl

# 디렉토리 생성 및 권한 설정
WEB_ROOT="/var/www/html"
BACKUP_ROOT="/var/www/backups"
DEPLOY_DIR="/home/ubuntu/deploy"

sudo mkdir -p "$BACKUP_ROOT" "$WEB_ROOT" "$DEPLOY_DIR"
sudo chown -R ubuntu:ubuntu "$BACKUP_ROOT" "$DEPLOY_DIR"
sudo chown -R www-data:www-data "$WEB_ROOT"
sudo usermod -a -G www-data ubuntu
sudo chmod 755 "$DEPLOY_DIR"
sudo chmod 775 "$WEB_ROOT"

# index.html 자동 복사
if [ -f "$DEPLOY_DIR/public/index.html" ]; then
    log "index.html 복사 중"
    sudo cp "$DEPLOY_DIR/public/index.html" "$WEB_ROOT/index.html"
    sudo chown www-data:www-data "$WEB_ROOT/index.html"
else
    log "index.html 파일이 $DEPLOY_DIR/public 에 없습니다. 수동 업로드 필요"
fi

# Nginx 설정 생성
cat > /tmp/frontend.conf <<EOF
server {
    listen 80;
    server_name _;
    root $WEB_ROOT;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location /static/ {
        expires 1y;
        add_header Cache-Control "public, no-transform";
    }

    error_page 404 /index.html;
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
EOF

# Nginx 설정 적용
sudo mv /tmp/frontend.conf /etc/nginx/sites-available/frontend
sudo ln -sf /etc/nginx/sites-available/frontend /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

log "Nginx 시작"
sudo nginx -t || handle_error "Nginx 설정 오류"
sudo systemctl enable nginx
sudo systemctl restart nginx || handle_error "Nginx 시작 실패"

# 헬스 체크
if curl -sSf http://localhost > /dev/null; then
    log "Nginx 헬스 체크 성공"
else
    log "Nginx는 실행 중이지만 응답이 없습니다 (index.html 누락 가능)"
fi

log "웹 서버 초기화 완료"
