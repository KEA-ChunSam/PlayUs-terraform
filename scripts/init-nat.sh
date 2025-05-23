#!/bin/bash

# 1. IP 포워딩 활성화
sysctl -w net.ipv4.ip_forward=1
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf

# 2. iptables로 NAT(Masquerade) 설정
# eth0: public, eth1: private (인터페이스명은 환경에 따라 다를 수 있음)
# OpenStack 기본은 eth0 하나만 잡히는 경우가 많으니, SNAT 대상 인터페이스를 꼭 확인하세요!

# 예시: eth0이 외부(퍼블릭) 네트워크라고 가정
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# 3. iptables-persistent 설치 및 규칙 영구화 (Ubuntu 기준)
apt-get update
apt-get install -y iptables-persistent
netfilter-persistent save

# 4. 부팅 시 자동 적용 보장
systemctl enable netfilter-persistent

# 5. 로그
echo "NAT 인스턴스 초기화 완료: IP 포워딩 및 Masquerade 설정됨"
