#!/bin/bash

# 웹 서버 초기화 스크립트 (단순 버전)

# 로그 함수
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 필수 패키지 설치
log "Nginx 설치 중"
sudo apt-get update
sudo apt-get install -y nginx

# 기본 index.html 생성
sudo tee /var/www/html/index.html > /dev/null <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>PlayUs Web Server</title>
    <meta charset="utf-8">
</head>
<body>
    <h1>Welcome to PlayUs!</h1>
    <p>Web server is running successfully.</p>
    <p>Server: $(hostname)</p>
    <p>Time: $(date)</p>
</body>
</html>
EOF

# Nginx 설정
sudo tee /etc/nginx/sites-available/default > /dev/null <<EOF
server {
    listen 80;
    server_name _;
    root /var/www/html;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

# Nginx 시작
log "Nginx 시작"
sudo systemctl enable nginx
sudo systemctl restart nginx

# 헬스 체크
if curl -sSf http://localhost > /dev/null; then
    log "Nginx 헬스 체크 성공"
else
    log "Nginx 헬스 체크 실패"
    exit 1
fi

log "웹 서버 초기화 완료"
