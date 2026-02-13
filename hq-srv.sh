#!/bin/bash
echo "Настройка HQ-SRV..."

apt-get update && apt-get install -y dnsmasq 
hostnamectl set-hostname hq-srv.au-team.irpo 
exec bash
timedatectl set-timezone Asia/Novosibirsk

sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g'  /etc/net/sysctl.conf
systemctl restart network

# Пользователь SSH
adduser --uid sshuser
echo "sshuser:P@ssw0rd" | chpasswd
echo "sshuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers
usermod -aG wheel sshuser

# SSH настройка
mkdir -p banner 
echo "
#######################
#Authorized access only
####################### " >/etc/banner 

sed -i 's/#Port 22/Port 2024/g' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
echo "Banner /etc/banner" > /etc/ssh/sshd_config
echo "AllowUsers sshuser" > /etc/ssh/sshd_config
systemctl restart sshd

# настройка dns
echo "domain=au-team.irpo
no-resolv
server=77.88.8.8
server=77.88.8.3
cache-size=1000
max-cache-ttl=86400
interface=ens19.100
address=/hq-srv.au-team.irpo/192.168.1.2
address=/hq-rtr.au-team.irpo/192.168.1.1
address=/hq-cli.au-team.irpo/192.168.2.2
address=/br-srv.au-team.irpo/10.10.1.2
address=/br-rtr.au-team.irpo/10.10.1.1
ptr-record=2.2.168.192.in-addr.arpa,hq-srv.au-team.irpo
ptr-record=1.1.168.192.in-addr.arpa,hq-rtr.au-team.irpo
ptr-record=2.2.168.192.in-addr.arpa,hq-cli.au-team.irpo
" > /etc/dnsmasq.d/au-team.conf

 echo "search au-team.irpo
nameserver 192.168.1.2
nameserver 77.88.8.8" > /etc/resolv.conf
systemctl enable --now dnsmasq


