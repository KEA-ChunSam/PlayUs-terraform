#!/bin/bash

# 웹 서버 환경 변수 설정
export ALB_VIP="${APP_ENDPOINT}"
export REACT_APP_API_URL="${APP_ENDPOINT}"
export NODE_ENV="production"
export DEPLOY_VERSION="terraform_init"

# 환경 변수를 파일로 저장
cat > /tmp/web-env << 'EOF'
ALB_VIP=${APP_ENDPOINT}
REACT_APP_API_URL=${APP_ENDPOINT}
NODE_ENV=production
DEPLOY_VERSION=terraform_init
EOF

# 환경 변수 로드 함수
load_web_env() {
    if [ -f /tmp/web-env ]; then
        source /tmp/web-env
    fi
}

# 환경 변수 로드
load_web_env 