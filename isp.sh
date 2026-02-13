#!/bin/bash
echo "Настройка ISP..."
apt-get update && apt-get install -y tzdata mc iptables

timedatectl set-timezone Asia/Novosibirsk
hostnamectl set-hostname isp

#настройка для  hq-rtr и br-rtr
mkdir -p /etc/net/ifaces/{ens20,ens21}
echo "172.16.1.1/28" > /etc/net/ifaces/ens20/ipv4address
echo "172.16.2.1/28" > /etc/net/ifaces/ens21/ipv4address
echo "TYPE=eth
BOOTPROTO=static
DISABLED=no
CONFIG_IPV4=yes
ONBOOT=yes" > /etc/net/ifaces/ens20/options 
echo "TYPE=eth
BOOTPROTO=static
DISABLED=no
CONFIG_IPV4=yes
ONBOOT=yes" > /etc/net/ifaces/ens21/options 

sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g'  /etc/net/sysctl.conf
systemctl restart network

iptables -t nat -A POSTROUTING -o ens19  -j MASQUERADE
iptables-save > /etc/sysconfig/iptables
systemctl enable --now iptables
