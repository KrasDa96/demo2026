#!/bin/bash
echo "Настройка BR-RTR..."

apt-get update && apt-get install -y tzdata mc iptables sudo  frr

timedatectl set-timezone Asia/Novosibirsk
hostnamectl set-hostname br-rtr.au-team.irpo 

#в сторону br-srv
mkdir -p /etc/net/ifaces/ens20
echo "10.10.1.1/28" > /etc/net/ifaces/ens20/ipv4address
echo "TYPE=eth
BOOTPROTO=static
ONBOOT=yes
CONFIG_IPV4=yes" > /etc/net/ifaces/ens20/options

sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g'  /etc/net/sysctl.conf

#настройка nat
iptables -t nat -A POSTROUTING -o ens19  -j MASQUERADE
iptables-save > /etc/sysconfig/iptables
systemctl enable --now iptables

# GRE туннель
mkdir -p /etc/net/ifaces/gre
echo "TYPE=gre
TUNLOCAL=172.16.2.2
TUNREMOTE=172.16.1.2" >/etc/net/ifaces/gre/options 
echo "172.16.100.2/29" > /etc/net/ifaces/gre/ipv4address
systemctl restart network
modprobe gre

# Пользователь
adduser net_admin
echo "net_admin:P@ssword" | chpasswd
usermod -aG wheel net_admin
echo "net_admin ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Настройка FRR (OSPF)
sed -i 's/ospfd=no/ospfd=yes/g' /etc/frr/daemons
systemctl restart frr

# Конфигурация frr
echo "firr.conf
firr version 10.2.2
firr defaults traditional
hostname hq-rrt.au-team.irpo
log file /var/log/frr/frr.log
no ipv6 forwarding
!
interface get
ip ospf authentication
ip ospf authentication-key PLAINPAS
no ip ospf passive
exit
!
router ospf
passive-interface default
network 10.10.1.0/28 area 0
network 172.16.100.0/29 area 0
exit
!"  >etc/frr/frr.conf



