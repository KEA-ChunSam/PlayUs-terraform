#!/bin/bash

# 로그 설정
exec > >(tee /var/log/user-data.log) 2>&1

echo "Starting k8s slave initialization"

# 시스템 업데이트
apt-get update
apt-get upgrade -y

# 컨테이너 런타임 설치 
apt-get install -y containerd
systemctl enable containerd
systemctl start containerd

# containerd 설정
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml

# SystemdCgroup 사용 설정 
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl restart containerd

# Kubernetes 설치를 위한 사전 준비
apt-get install -y apt-transport-https ca-certificates curl

# Kubernetes 저장소 키 추가
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

# Kubernetes 저장소 추가
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list

# 패키지 목록 업데이트
apt-get update

# Kubernetes 도구 설치 
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# 스왑 비활성화
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 시스템 설정
echo 'net.bridge.bridge-nf-call-iptables = 1' >> /etc/sysctl.conf
echo 'net.bridge.bridge-nf-call-ip6tables = 1' >> /etc/sysctl.conf
sysctl --system

echo "k8s slave initialization completed"
echo "Ready for kubeadm join command" 
