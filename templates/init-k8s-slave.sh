#!/bin/bash

# 로그 설정
exec > >(tee /var/log/k8s-worker-init.log) 2>&1

echo "[INFO] Starting Kubernetes worker initialization"

# 시스템 업데이트
apt-get update && apt-get upgrade -y

# containerd 설치 및 설정
apt-get install -y containerd
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml >/dev/null
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# 필요한 패키지 설치
apt-get install -y apt-transport-https ca-certificates curl gpg

# Kubernetes 저장소 등록 (v1.30 기준 최신)
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | \
  gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
  https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | \
  tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# 스왑 비활성화
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# 커널 설정
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

echo "[INFO] Kubernetes worker initialization completed."
echo "[INFO] Ready to join the cluster using: sudo kubeadm join ..."
