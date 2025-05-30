#!/bin/bash

# 1. IP 포워딩 활성화
sysctl -w net.ipv4.ip_forward=1
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf

# 2. iptables로 NAT(Masquerade) 설정
# 외부 네트워크 인터페이스 자동 감지
EXTERNAL_IF=$(ip route | grep default | awk '{print $5}' | head -1)
echo "외부 네트워크 인터페이스: $EXTERNAL_IF"

# SNAT 설정 (Masquerade)
iptables -t nat -A POSTROUTING -o $EXTERNAL_IF -j MASQUERADE
echo "SNAT 규칙 추가: iptables -t nat -A POSTROUTING -o $EXTERNAL_IF -j MASQUERADE"

# 3. iptables-persistent 설치 및 규칙 영구화 (Ubuntu 기준)
apt-get update
apt-get install -y iptables-persistent
netfilter-persistent save

# 4. 부팅 시 자동 적용 보장
systemctl enable netfilter-persistent

# 5. 로그
echo "NAT 인스턴스 초기화 완료: IP 포워딩 및 Masquerade 설정됨"
