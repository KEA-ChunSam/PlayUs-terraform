#!/bin/bash

# 로그 설정
exec > >(tee /var/log/user-data.log) 2>&1

echo "Starting k8s master initialization"

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

# 잠시 대기
sleep 30

echo "Initializing Kubernetes cluster..."

# 클러스터 초기화 (containerd 런타임 사용)
kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$(hostname -I | awk '{print $1}') --cri-socket=unix:///run/containerd/containerd.sock

# kubectl 설정 (root 사용자용)
mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config

# ubuntu 사용자용 kubectl 설정
mkdir -p /home/ubuntu/.kube
cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config

# Flannel 네트워크 플러그인 설치
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# 조인 명령어를 파일에 저장 (나중에 슬레이브들이 사용할 수 있도록)
kubeadm token create --print-join-command > /tmp/kubeadm-join-command.sh
chmod +x /tmp/kubeadm-join-command.sh

echo "k8s master initialization completed"
echo "Join command saved to /tmp/kubeadm-join-command.sh" 
