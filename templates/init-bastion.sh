#!/bin/bash

# Bastion 서버 초기화 스크립트

# 로그 설정
LOG_FILE="/var/log/bastion-init.log"
exec > >(tee -a "$LOG_FILE")
exec 2>&1

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 로깅 함수
log_info() {
    echo -e "${GREEN}[INFO $(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN $(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR $(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP $(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# 에러 처리 함수
handle_error() {
    log_error "$1"
    log_error "스크립트 실행 실패. 로그를 확인하세요: $LOG_FILE"
    exit 1
}

# 재시도 함수
retry_command() {
    local max_attempts=$1
    local delay=$2
    shift 2
    local command="$@"
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log_info "명령 실행 시도 ($attempt/$max_attempts): $command"
        if eval "$command"; then
            log_info "명령 실행 성공"
            return 0
        else
            if [ $attempt -eq $max_attempts ]; then
                log_error "명령 실행 실패 (최대 시도 횟수 초과): $command"
                return 1
            fi
            log_warn "명령 실행 실패. ${delay}초 후 재시도..."
            sleep $delay
            ((attempt++))
        fi
    done
}

# 시스템 정보 출력
print_system_info() {
    log_step "시스템 정보 확인"
    echo "======================================"
    echo "호스트명: $(hostname)"
    echo "OS: $(lsb_release -d | cut -f2)"
    echo "커널: $(uname -r)"
    echo "아키텍처: $(uname -m)"
    echo "CPU 코어: $(nproc)"
    echo "총 메모리: $(free -h | awk '/^Mem:/ {print $2}')"
    echo "사용 가능한 메모리: $(free -h | awk '/^Mem:/ {print $7}')"
    echo "디스크 사용량: $(df -h / | awk 'NR==2 {print $3"/"$2" ("$5")"}')"
    echo "======================================"
}

# APT 업데이트
update_system() {
    log_step "시스템 업데이트"
    
    # APT 업데이트
    log_info "패키지 목록 업데이트 중..."
    retry_command 3 10 "sudo apt-get update" || handle_error "APT 업데이트 실패"
    
    # 필수 패키지 설치
    log_info "필수 패키지 설치 중..."
    retry_command 3 5 "sudo apt-get install -y curl wget git htop vim nano unzip" || handle_error "필수 패키지 설치 실패"
    
    log_info "시스템 업데이트 완료"
}

# Docker 설치
install_docker() {
    log_step "Docker 설치"
    
    # Docker가 이미 설치되어 있는지 확인
    if command -v docker &> /dev/null; then
        local docker_version=$(docker --version)
        log_info "Docker가 이미 설치되어 있습니다: $docker_version"
        return 0
    fi
    
    # 필수 패키지 설치
    log_info "Docker 설치를 위한 필수 패키지 설치 중..."
    retry_command 3 5 "sudo apt-get install -y ca-certificates curl gnupg lsb-release" || handle_error "필수 패키지 설치 실패"
    
    # Docker GPG 키 추가
    log_info "Docker GPG 키 추가 중..."
    sudo mkdir -p /etc/apt/keyrings
    retry_command 3 5 "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg" || handle_error "Docker GPG 키 추가 실패"
    
    # Docker 저장소 추가
    log_info "Docker 저장소 추가 중..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # 패키지 목록 업데이트
    retry_command 3 5 "sudo apt-get update" || handle_error "Docker 저장소 업데이트 실패"
    
    # Docker 설치
    log_info "Docker 설치 중..."
    retry_command 3 10 "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin" || handle_error "Docker 설치 실패"
    
    # Docker Compose 설치
    log_info "Docker Compose 설치 중..."
    retry_command 3 5 "sudo apt-get install -y docker-compose" || log_warn "Docker Compose standalone 설치 실패"
    
    # Docker 서비스 설정
    log_info "Docker 서비스 설정 중..."
    sudo systemctl start docker || handle_error "Docker 서비스 시작 실패"
    sudo systemctl enable docker || handle_error "Docker 서비스 자동 시작 설정 실패"
    
    # 사용자를 docker 그룹에 추가
    sudo usermod -aG docker ubuntu || handle_error "사용자 docker 그룹 추가 실패"
    
    log_info "Docker 설치 완료"
}

# Nginx Proxy Manager 설정
setup_nginx_proxy_manager() {
    log_step "Nginx Proxy Manager 설정"
    
    local npm_dir="$HOME/nginx-proxy-manager"
    
    # 디렉토리 생성
    log_info "Nginx Proxy Manager 디렉토리 생성 중..."
    mkdir -p "$npm_dir"
    cd "$npm_dir"
    
    # Docker Compose 파일 생성
    log_info "Docker Compose 설정 파일 생성 중..."
    cat << 'EOF' > docker-compose.yaml
version: "3.8"
services:
  app:
    image: 'jc21/nginx-proxy-manager:2.9.20'
    restart: unless-stopped
    ports:
      - '80:80'      # HTTP
      - '443:443'    # HTTPS
      - '81:81'      # Admin Web UI
      - '10000-10199:10000-10199'  # Port forwarding range
    environment:
      DB_MYSQL_HOST: "db"
      DB_MYSQL_PORT: 3306
      DB_MYSQL_USER: "npm"
      DB_MYSQL_PASSWORD: "npm"
      DB_MYSQL_NAME: "npm"
      DISABLE_IPV6: 'true'
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
    depends_on:
      - db

  db:
    image: 'jc21/mariadb-aria:latest'
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: 'npm'
      MYSQL_DATABASE: 'npm'
      MYSQL_USER: 'npm'
      MYSQL_PASSWORD: 'npm'
    volumes:
      - ./data/mysql:/var/lib/mysql
EOF
    
    # Docker Compose 실행
    log_info "Nginx Proxy Manager 시작 중..."
    sudo docker-compose up -d || handle_error "Nginx Proxy Manager 시작 실패"
    
    # 서비스 시작 대기
    log_info "서비스 시작 대기 중..."
    sleep 30
    
    # 컨테이너 상태 확인
    log_info "컨테이너 상태:"
    sudo docker-compose ps
    
    log_info "Nginx Proxy Manager 설치 완료"
    log_info "관리 페이지: http://$(curl -s ifconfig.me):81"
    log_info "기본 로그인: admin@example.com / changeme"
}

# 방화벽 설정
setup_firewall() {
    log_step "방화벽 설정"
    
    # UFW 설치 및 설정
    sudo apt-get install -y ufw
    
    # 기본 정책 설정
    sudo ufw --force reset
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # 필요한 포트 허용
    sudo ufw allow 22/tcp      # SSH
    sudo ufw allow 80/tcp      # HTTP
    sudo ufw allow 443/tcp     # HTTPS
    sudo ufw allow 81/tcp      # NPM Admin
    sudo ufw allow 10000:10199/tcp  # Port forwarding range
    
    # UFW 활성화
    sudo ufw --force enable
    
    log_info "방화벽 설정 완료"
    sudo ufw status
}

# 메인 실행 함수
main() {
    log_info "🚀 Bastion 서버 초기화 시작"
    
    print_system_info
    update_system
    install_docker
    setup_nginx_proxy_manager
    setup_firewall
    
    log_info "Bastion 서버 초기화 완료!"
    log_info "다음 단계:"
    log_info "1. Nginx Proxy Manager 관리 페이지 접속: http://$(curl -s ifconfig.me):81"
    log_info "2. 기본 로그인: admin@example.com / changeme"
    log_info "3. 포트 포워딩 설정 진행"
}

# 스크립트 실행
main "$@" 
