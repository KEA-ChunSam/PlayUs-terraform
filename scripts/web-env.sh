#!/bin/bash
# PlayUs-FE 프론트엔드 빌드용 .env 파일 (필요한 항목만)

cat <<EOF > /home/ubuntu/PlayUs-FE/.env
REACT_APP_APP_ENDPOINT=${APP_ENDPOINT}
REACT_APP_SENTRY_DSN=https://827f0d242113917609e71527db4fd2da@o4509111730634752.ingest.us.sentry.io/4509111732142080
REACT_APP_ENVIRONMENT=prod
REACT_APP_SENTRY_REPOSITORY_URI=https://chunsam.sentry.io/issues/?project=4509304771706880&statusPeriod=24h
REACT_APP_SENTRY_DSN=https://10230434fb25e8a6b7490c1969d82d32@o4509304545673216.ingest.us.sentry.io/4509304771706880
REACT_APP_SLACK_WEBHOOK_URL=http://129.154.50.74/webhook/slack/playus
REACT_APP_LOCAL_BACKEND_URI=http://localhost:8080
REACT_APP_LOCAL_BACKEND_TWP_URI=http://localhost:8081
REACT_APP_LOCAL_BACKEND_COMMUNITY_URI=http://localhost:8082
REACT_APP_PROFANITY_DETECT_API_BASE=https://xrnfbckpskycrstm.tunnel.elice.io/detect
EOF
