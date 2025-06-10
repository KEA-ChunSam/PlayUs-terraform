#!/bin/bash

# 환경 변수 설정 (웹 서버용)
export ALB_VIP="${APP_ENDPOINT}"
export REACT_APP_API_URL="${APP_ENDPOINT}"
export NODE_ENV="production"
export DEPLOY_VERSION="terraform_init"

# /tmp/web-env 파일 생성
cat > /tmp/web-env <<EOF
ALB_VIP=${APP_ENDPOINT}
REACT_APP_API_URL=${APP_ENDPOINT}
NODE_ENV=production
DEPLOY_VERSION=terraform_init
EOF
