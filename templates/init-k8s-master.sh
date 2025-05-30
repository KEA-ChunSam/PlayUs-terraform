#!/bin/bash

# 로그 설정
exec > >(tee /var/log/k8s-master-init.log) 2>&1

echo "[INFO] Starting Kubernetes master initialization"

# 시스템 업데이트
apt-get update && apt-get upgrade -y

# 컨테이너 런타임 설치
apt-get install -y containerd
systemctl enable containerd
systemctl start containerd

# containerd 설정
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml >/dev/null
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd

# Kubernetes 설치 준비
apt-get install -y apt-transport-https ca-certificates curl gpg

# GPG 키 및 저장소 추가 (k8s 1.30 기준)
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

# 커널 파라미터 설정
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

sleep 10

# Master IP 추출
MASTER_IP=$(ip -4 addr show scope global | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
echo "[INFO] Using Master IP: $MASTER_IP"

# kubeadm 초기화
kubeadm init --apiserver-advertise-address=$MASTER_IP \
  --pod-network-cidr=10.244.0.0/16 \
  --cri-socket=unix:///run/containerd/containerd.sock

# kubectl 설정 (root & ubuntu)
mkdir -p /root/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config

mkdir -p /home/ubuntu/.kube
cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config

# Flannel 설치
echo "[INFO] Installing Flannel CNI plugin..."
sleep 10
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

echo "[INFO] Waiting for Flannel to be ready..."
kubectl wait --for=condition=ready pod -l app=flannel -n kube-flannel --timeout=300s

# 워커 조인 명령어 생성
echo "[INFO] Generating worker join command..."
kubeadm token create --print-join-command > /tmp/kubeadm-join-command.sh
chmod +x /tmp/kubeadm-join-command.sh

echo "[SUCCESS] Kubernetes master initialization completed"
echo "[INFO] Join command saved at: /tmp/kubeadm-join-command.sh"
echo "[INFO] You can view it with: cat /tmp/kubeadm-join-command.sh"
