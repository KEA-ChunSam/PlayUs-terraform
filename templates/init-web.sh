#!/bin/bash

# 환경 변수 로드
if [ -f /tmp/web-env ]; then
    source /tmp/web-env
fi

# 환경 변수 설정
WEB_ROOT="/var/www/html"
BACKUP_ROOT="/var/www/backups"
APP_DIR="/home/ubuntu/PlayUs-FE"
DEPLOY_DIR="/home/ubuntu/deploy"
DEPLOY_VERSION=$(git rev-parse HEAD 2>/dev/null || echo "manual_deploy_$(date +%Y%m%d_%H%M%S)")
NODE_ENV="${NODE_ENV:-production}"
SLACK_WEBHOOK_URL=""  # Slack 웹훅 URL 설정 필요

# 로깅 함수
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 에러 처리 함수
handle_error() {
    log "ERROR: $1"
    if [ ! -z "$SLACK_WEBHOOK_URL" ]; then
        send_slack_notification "실패" "❌" "#ff0000" "$1"
    fi
    exit 1
}

# Slack 알림 함수
send_slack_notification() {
    local status=$1
    local emoji=$2
    local color=$3
    local error_msg=$4

    local payload='{
        "attachments": [{
            "color": "'"$color"'",
            "blocks": [
                {
                    "type": "header",
                    "text": {
                        "type": "plain_text",
                        "text": "'"$emoji"' PlayUs 배포 '"$status"'",
                        "emoji": true
                    }
                },
                {
                    "type": "section",
                    "fields": [
                        {
                            "type": "mrkdwn",
                            "text": "*버전:*\n'"${DEPLOY_VERSION:0:7}"'"
                        },
                        {
                            "type": "mrkdwn",
                            "text": "*배포 시간:*\n'"$(date '+%Y-%m-%d %H:%M:%S KST')"'"
                        }
                    ]
                },
                {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": "*배포 환경:*\n'"$NODE_ENV"'"
                    }
                }'
    
    if [ ! -z "$error_msg" ]; then
        payload+=',{
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": "*에러 메시지:*\n'"$error_msg"'"
                    }
                }'
    fi
    
    payload+=']}]}'

    curl -s -X POST -H 'Content-type: application/json' \
        --data "$payload" \
        "$SLACK_WEBHOOK_URL" || true
}

# 필수 패키지 설치
log "필수 패키지 설치 중..."
sudo apt-get update
sudo apt-get install -y git curl jq nginx rsync

# Node.js 18.x LTS 설치
NODE_VERSION=$(node -v 2>/dev/null || echo "none")
if [ "$NODE_VERSION" = "none" ] || [[ ! "$NODE_VERSION" =~ ^v18\. ]]; then
    log "Node.js 18.x 설치 중..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    log "Node.js $(node -v) 설치 완료"
fi

# 디렉토리 생성 및 권한 설정
log "디렉토리 설정 중..."
sudo mkdir -p "$BACKUP_ROOT" "$WEB_ROOT" "$DEPLOY_DIR"
sudo chown -R ubuntu:ubuntu "$BACKUP_ROOT" "$DEPLOY_DIR"
sudo chown -R www-data:www-data "$WEB_ROOT"

# ubuntu 사용자를 www-data 그룹에 추가 (CI/CD 배포를 위해)
sudo usermod -a -G www-data ubuntu

# 배포 디렉토리 권한 설정 (CI/CD에서 접근 가능하도록)
sudo chmod 755 "$DEPLOY_DIR"
sudo chmod 775 "$WEB_ROOT"

# PlayUs-FE 클론 및 설정 (초기 설정 시에만)
if [ ! -f "/tmp/cicd_deployed" ]; then
    log "PlayUs-FE 초기 설정 중..."
    if [ -d "$APP_DIR" ]; then
        log "기존 PlayUs-FE 디렉토리 백업 중..."
        timestamp=$(date +%Y%m%d_%H%M%S)
        sudo mv "$APP_DIR" "${APP_DIR}_${timestamp}"
    fi

    # ubuntu 사용자로 모든 작업을 하나의 명령으로 실행
    su - ubuntu -c "
        cd /home/ubuntu && \
        git clone https://github.com/KEA-ChunSam/PlayUs-FE.git && \
        cd $APP_DIR && \
        
        # .env 파일 생성
        cat > .env << 'ENVEOF'
# API 엔드포인트
REACT_APP_API_URL=${ALB_VIP:-http://localhost:8080}

# 배포 정보
REACT_APP_VERSION=${DEPLOY_VERSION}
REACT_APP_BUILD_TIME=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

# 기타 환경 변수
NODE_ENV=${NODE_ENV}
ENVEOF

        # .gitignore에 .env 추가
        if ! grep -q '^.env$' .gitignore; then
            echo '.env' >> .gitignore
        fi && \
        
        # 의존성 설치 및 빌드
        npm ci && \
        npm run build && \
        
        # 버전 정보 파일 생성
        echo '{\"version\": \"${DEPLOY_VERSION}\", \"deployedAt\": \"$(date -u +'%Y-%m-%dT%H:%M:%SZ')\"}' > build/version.json
    " || handle_error "빌드 실패"

    # 이전 배포 백업
    log "이전 배포 백업 중..."
    timestamp=$(date +%Y%m%d_%H%M%S)
    BACKUP_DIR="$BACKUP_ROOT/backup_${timestamp}"
    sudo mkdir -p "$BACKUP_DIR"
    sudo cp -r "$WEB_ROOT"/* "$BACKUP_DIR/" 2>/dev/null || true
    echo "$BACKUP_DIR" > /tmp/latest_backup

    # 새 배포 적용
    log "새 배포 적용 중..."
    sudo rm -rf "$WEB_ROOT"/*
    sudo cp -r "$APP_DIR/build"/* "$WEB_ROOT"/
    sudo chown -R www-data:www-data "$WEB_ROOT"
fi

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

    # SPA 라우팅
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # 정적 파일 캐싱
    location /static/ {
        expires 1y;
        add_header Cache-Control "public, no-transform";
    }

    # API 프록시
    location /api {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
    }

    # 헬스 체크 엔드포인트
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
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

# Nginx 설정 테스트 및 재시작
log "Nginx 재시작 중..."
sudo nginx -t || handle_error "Nginx 설정 테스트 실패"
sudo systemctl enable nginx
sudo systemctl restart nginx || handle_error "Nginx 재시작 실패"

# 헬스 체크
log "헬스 체크 중..."
for i in {1..5}; do
    if curl -f http://localhost/health > /dev/null 2>&1; then
        log "헬스 체크 성공"
        break
    fi
    if [ $i -eq 5 ]; then
        handle_error "헬스 체크 실패"
    fi
    log "시도 $i: 헬스 체크 실패, 10초 후 재시도..."
    sleep 10
done

# 오래된 백업 정리 (7일 이상 된 백업)
log "오래된 백업 정리 중..."
find "$BACKUP_ROOT/backup_*" -maxdepth 0 -mtime +7 -exec rm -rf {} \; 2>/dev/null || true

# 배포 스크립트 생성 (CI/CD에서 사용)
cat > /home/ubuntu/deploy.sh << "EOF"
#!/bin/bash

WEB_ROOT="/var/www/html"
BACKUP_ROOT="/var/www/backups"
DEPLOY_DIR="/home/ubuntu/deploy"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 백업 생성
log "배포 백업 생성 중..."
timestamp=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/backup_${timestamp}"
sudo mkdir -p "$BACKUP_DIR"
sudo cp -r "$WEB_ROOT"/* "$BACKUP_DIR/" 2>/dev/null || true
echo "$BACKUP_DIR" > /tmp/latest_backup

# 새 배포 적용
log "새 배포 적용 중..."
if [ -d "$DEPLOY_DIR" ] && [ "$(ls -A $DEPLOY_DIR)" ]; then
    sudo rm -rf "$WEB_ROOT"/*
    sudo cp -r "$DEPLOY_DIR"/* "$WEB_ROOT"/
    sudo chown -R www-data:www-data "$WEB_ROOT"
    sudo rm -rf "$DEPLOY_DIR"/*
    log "배포 완료"
else
    log "배포할 파일이 없습니다"
    exit 1
fi
EOF

chmod +x /home/ubuntu/deploy.sh

# 롤백 스크립트 생성
cat > /home/ubuntu/rollback.sh << "EOF"
#!/bin/bash

WEB_ROOT="/var/www/html"
BACKUP_ROOT="/var/www/backups"

if [ -z "$1" ]; then
    echo "Usage: ./rollback.sh <backup_timestamp>"
    echo "Available backups:"
    ls -1 "$BACKUP_ROOT" | grep "^backup_" | sort -r
    exit 1
fi

if [ ! -d "$BACKUP_ROOT/backup_$1" ]; then
    echo "Error: Backup backup_$1 not found"
    exit 1
fi

echo "Rolling back to backup backup_$1..."
sudo rm -rf "$WEB_ROOT"/*
sudo cp -r "$BACKUP_ROOT/backup_$1"/* "$WEB_ROOT"/
sudo chown -R www-data:www-data "$WEB_ROOT"
sudo systemctl restart nginx
echo "Rollback completed"
EOF

chmod +x /home/ubuntu/rollback.sh

# 성공 알림
if [ ! -z "$SLACK_WEBHOOK_URL" ]; then
    send_slack_notification "성공" "✅" "#36a64f"
fi

log "웹 서버 초기화 완료"
