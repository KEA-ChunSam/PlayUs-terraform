#!/bin/bash

# Kubernetes 마스터 노드 설치 스크립트

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

log_warning "새로운 Kubernetes 클러스터를 설치합니다."
# 자동화를 위해 사용자 입력 제거
# read -p "계속하시겠습니까? (y/N): " -n 1 -r
# echo
# if [[ ! $REPLY =~ ^[Yy]$ ]]; then
#     exit 1
# fi

# ================================
# 1. 설치 시작
# ================================
log_info "새로운 Kubernetes 클러스터 설치 시작..."

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

# 기존 containerd 제거
systemctl stop containerd 2>/dev/null || true
apt-get remove -y containerd.io docker-ce docker-ce-cli 2>/dev/null || true

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
# 6. 클러스터 초기화
# ================================
log_info "Kubernetes 클러스터 초기화..."

# 마스터 IP 자동 감지
MASTER_IP=$(ip route get 8.8.8.8 | awk '{print $7; exit}')
log_info "마스터 노드 IP: $MASTER_IP"

# Pod CIDR (Calico 기본값)
POD_CIDR="192.168.0.0/16"

# kubeadm init
kubeadm init \
    --apiserver-advertise-address=$MASTER_IP \
    --pod-network-cidr=$POD_CIDR \
    --service-cidr=10.96.0.0/12 \
    --cri-socket=unix:///var/run/containerd/containerd.sock \
    --ignore-preflight-errors=all

# ================================
# 7. kubectl 설정
# ================================
log_info "kubectl 설정..."

# root 사용자
mkdir -p $HOME/.kube
cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# sudo 사용자가 있다면
if [ -n "$SUDO_USER" ]; then
    sudo -u $SUDO_USER mkdir -p /home/$SUDO_USER/.kube
    cp -f /etc/kubernetes/admin.conf /home/$SUDO_USER/.kube/config
    chown $SUDO_USER:$SUDO_USER /home/$SUDO_USER/.kube/config
fi

# ================================
# 8. Calico 설치 (BGP 비활성화)
# ================================
log_info "Calico CNI 설치 (BGP 비활성화 모드)..."

# Calico Operator 설치
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml

# BGP 비활성화된 Calico 설정 적용
cat <<EOF | kubectl apply -f -
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    bgp: Disabled
    ipPools:
    - blockSize: 26
      cidr: $POD_CIDR
      encapsulation: VXLAN
      natOutgoing: Enabled
      nodeSelector: all()
    nodeAddressAutodetectionV4:
      firstFound: true
---
apiVersion: operator.tigera.io/v1
kind: APIServer
metadata:
  name: default
spec: {}
EOF

log_info "Calico 설치 완료. BGP는 비활성화되고 VXLAN 모드로 설정되었습니다."

# ================================
# 9. Helm 설치
# ================================
log_info "Helm 설치..."

curl https://baltocdn.com/helm/signing.asc | gpg --dearmor > /usr/share/keyrings/helm.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" > /etc/apt/sources.list.d/helm-stable-debian.list

apt-get update -y
apt-get install -y helm

# ================================
# 10. 클러스터 상태 확인
# ================================
log_info "클러스터 준비 상태 확인 중..."

echo "Calico 파드가 준비될 때까지 대기 중... (최대 5분)"
for i in {1..30}; do
    if kubectl get pods -n calico-system | grep -q "Running.*1/1"; then
        log_success "Calico 파드가 준비되었습니다!"
        break
    fi
    echo "대기 중... ($i/30)"
    sleep 10
done

# ================================
# 11. 결과 출력
# ================================
log_success "Kubernetes 클러스터 설치 완료!"

echo ""
echo "=============================================="
echo "설치 정보"
echo "=============================================="
echo "- Kubernetes 버전: $(kubectl version --short --client 2>/dev/null || echo "확인 중...")"
echo "- 마스터 노드 IP: $MASTER_IP"
echo "- Pod Network CIDR: $POD_CIDR"
echo "- CNI: Calico (VXLAN 모드, BGP 비활성화)"
echo ""

echo "노드 상태:"
kubectl get nodes -o wide || echo "노드 상태 확인 중..."

echo ""
echo "시스템 파드 상태:"
kubectl get pods -n kube-system || echo "시스템 파드 확인 중..."

echo ""
echo "Calico 파드 상태:"
kubectl get pods -n calico-system || echo "Calico 파드 확인 중..."

echo ""
echo "=============================================="
echo "다음 단계"
echo "=============================================="
echo ""
echo "1. 워커 노드 추가 명령어:"
echo "   (각 워커 노드에서 실행)"
echo ""
kubeadm token create --print-join-command 2>/dev/null || echo "   토큰 생성 중 오류 발생"
echo ""

echo "2. 일반 사용자 kubectl 설정:"
echo "   mkdir -p \$HOME/.kube"
echo "   sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config"
echo "   sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config"
echo ""

echo "3. 클러스터 확인 명령어:"
echo "   kubectl get nodes"
echo "   kubectl get pods -A"
echo "   kubectl describe nodes"
echo ""

echo "4. Calico 상태 확인:"
echo "   kubectl get pods -n calico-system"
echo "   kubectl logs -n calico-system -l k8s-app=calico-node"
echo ""

log_success "설치가 완료되었습니다!"
log_info "만약 여전히 문제가 있다면 다음을 확인하세요:"
echo "- 방화벽 설정 (ufw status)"
echo "- 네트워크 인터페이스 상태 (ip addr)"
echo "- containerd 로그 (journalctl -u containerd)"
