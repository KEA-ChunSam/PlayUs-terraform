#!/bin/bash

# 필수 패키지 설치
sudo apt-get update
sudo apt-get install -y git curl

# Node.js 18.x LTS 설치
NODE_VERSION=$(node -v 2>/dev/null || echo "none")
if [ "$NODE_VERSION" = "none" ] || [[ ! "$NODE_VERSION" =~ ^v18\. ]]; then
  echo "Node.js 18.x 설치 중..."
  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
  sudo apt-get install -y nodejs
  echo "Node.js $(node -v) 설치 완료"
fi

# nginx 설치
sudo apt-get install -y nginx

# PlayUs-FE 클론
cd /home/ubuntu
sudo rm -rf PlayUs-FE
sudo -u ubuntu git clone https://github.com/KEA-ChunSam/PlayUs-FE.git

# .env 파일 생성 (generate-web-env.sh 실행)
sudo bash /home/ubuntu/scripts/generate-web-env.sh

# .env 파일 존재 확인
if [ ! -f /home/ubuntu/PlayUs-FE/.env ]; then
  echo ".env 파일이 없습니다. generate-web-env.sh를 확인하세요."
  exit 1
fi

# 빌드 및 배포
cd /home/ubuntu/PlayUs-FE
sudo -u ubuntu npm install
sudo -u ubuntu npm run build

sudo rm -rf /var/www/html/*
sudo cp -r dist/* /var/www/html/
sudo chown -R www-data:www-data /var/www/html
sudo systemctl restart nginx
