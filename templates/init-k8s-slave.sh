#!/bin/bash

# Kubernetes 워커 노드 설치 스크립트

set -e

# 색상 코드
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

error_exit() {
    log_error "$1"
    exit 1
}

if [ "$EUID" -ne 0 ]; then
    error_exit "root 권한으로 실행하세요: sudo $0"
fi

# 워커 노드 기본 설치 (join은 수동으로)

log_warning "새로운 Kubernetes 워커 노드를 설치합니다."
# 자동화를 위해 사용자 입력 제거
# read -p "계속하시겠습니까? (y/N): " -n 1 -r
# echo
# if [[ ! $REPLY =~ ^[Yy]$ ]]; then
#     exit 1
# fi

# ================================
# 1. 설치 시작
# ================================
log_info "새로운 Kubernetes 워커 노드 설치 시작..."

# ================================
# 2. 시스템 준비
# ================================
log_info "시스템 업데이트 및 패키지 설치..."

apt-get update -y
apt-get upgrade -y

apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    wget \
    vim \
    net-tools \
    htop

# ================================
# 3. Swap 및 시스템 설정
# ================================
log_info "시스템 설정 중..."

# Swap 비활성화
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 커널 모듈
cat <<EOF > /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# 네트워크 설정
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
net.ipv4.conf.all.forwarding        = 1
EOF

sysctl --system

# ================================
# 4. containerd 설치 및 설정
# ================================
log_info "containerd 설치 및 설정..."

# Docker 저장소 추가
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y containerd.io

# containerd 설정
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml

# SystemdCgroup 활성화 (중요!)
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd

# ================================
# 5. Kubernetes 설치
# ================================
log_info "Kubernetes 패키지 설치..."

# Kubernetes 저장소 추가 (최신 방식)
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' > /etc/apt/sources.list.d/kubernetes.list

apt-get update -y
apt-get install -y kubelet kubeadm kubectl

apt-mark hold kubelet kubeadm kubectl
systemctl enable kubelet

# ================================
# 6. 설치 완료
# ================================
log_success "워커 노드 기본 설치 완료!"

echo ""
echo "=============================================="
echo "설치 정보"
echo "=============================================="
echo "- 워커 노드 IP: $(ip route get 8.8.8.8 | awk '{print $7; exit}')"
echo "- Kubernetes 버전: $(kubelet --version)"
echo "- 컨테이너 런타임: containerd"
echo ""

echo "=============================================="
echo "클러스터 조인 방법"
echo "=============================================="
echo ""
echo "1. 마스터 노드에서 join 명령어 생성:"
echo "   kubeadm token create --print-join-command"
echo ""
echo "2. 이 워커 노드에서 join 명령어 실행:"
echo "   sudo kubeadm join <마스터IP>:6443 --token <토큰> --discovery-token-ca-cert-hash <해시>"
echo ""
echo "3. 마스터 노드에서 노드 상태 확인:"
echo "   kubectl get nodes -o wide"
echo ""

log_success "워커 노드 준비가 완료되었습니다!"
log_info "이제 수동으로 클러스터에 조인하세요."
