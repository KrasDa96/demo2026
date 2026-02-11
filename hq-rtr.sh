#!/bin/bash
echo "Настройка HQ-RTR..."

apt-get update && apt-get install -y tzdata mc iptables sudo dhcp-server frr bind-utils

timedatectl set-timezone Asia/Novosibirsk
hostnamectl set-hostname hq-rtr.au-team.irpo

#настройка vlan
mkdir -p /etc/net/ifaces/{ens20.100,ens20.200,ens20.999,gre}
echo "192.168.1.1/27" > /etc/net/ifaces/ens20.100/ipv4address
echo "TYPE=vlan
HOST=ens20
VID=100
BOOTPROTO=static
DISABLED=no
ONBOOT=yes
CONFIG_IPV4=yes
" >/etc/net/ifaces/ens20.100/options 
echo "192.168.2.1/27" > /etc/net/ifaces/ens20.200/ipv4address
echo "TYPE=vlan
HOST=ens20
VID=200
BOOTPROTO=static
ONBOOT=yes
CONFIG_IPV4=yes
DISABLED=no
" >/etc/net/ifaces/ens20.200/options 
echo "192.168.3.1/29" > /etc/net/ifaces/ens20.999/ipv4address
echo "TYPE=vlan
HOST=ens20
VID=999
BOOTPROTO=static
ONBOOT=yes
CONFIG_IPV4=yes
DISABLED=no
" >/etc/net/ifaces/ens20.999/options 

sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g'  /etc/net/sysctl.conf
systemctl restart network

#настройка nat
iptables -t nat -A POSTROUTING -o ens19  -j MASQUERADE
iptables-save > /etc/sysconfig/iptables
systemctl enable --now iptables

# Пользователь
adduser net_admin
echo "net_admin:P@ssword" | chpasswd
usermod -aG wheel net_admin
echo "net_admin ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers

# Настройка FRR (OSPF)
sed -i 's/ospfd=no/ospfd=yes/g' /etc/frr/daemons
systemctl restart frr

# Конфигурация frr
vtysh
configure terminal
router ospf
passive-innterfase default
network 192.168.1.0/27 area 0
network 192.168.2.0/27 area 0
network 172.16.100.0/29 area 0
exit
interface gre
no ip ospf network broadcast
no ip ospf passive
exit
do wr mem
exit

# Пароля для frr
configure terminal
interface gre
ip ospf authentication
ip ospf aythentification-key PLAINPAS
exit
do wr mem
exit

#настройка gre
 echo "TYPE=gre
TUNLOCAL=172.16.1.2
TUNREMOTE=172.16.2.2" >/etc/net/ifaces/gre/options
echo "172.16.100.1/29" > /etc/net/ifaces/gre/ipv4address
systemctl restart network
modprobe gre

#настройка dhchd
systemctl enable --now dhcpd
Systemctl start dhcpd
echo "ddns-update-style none;
    subnet 192.168.2.0 netmask 255.255.255.240 {
    option routers 		192.168.2.1;
    option subnet-mask 		255.255.255.240;
    option domain-name		 'au-team.irpo';
    option domain-name-servers	192.168.1.2;
    range dynamic-bootp 192.168.2.10 192.168.2.14; 
    default-lease-time 21600;
    max-lease-time 43200;
    }
    " >/etc/dhcp/dhcpd.conf 
sed -i 's/DHCPDARGS=/DHCPDARGS=ens20.200/g'  /etc/sysconfig/dhcpd  

