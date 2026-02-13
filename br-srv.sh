#!/bin/bash
echo "Настройка BR-SRV..."
hostnamectl set-hostname br-srv.au-team.irpo
exec bash
timedatectl set-timezone Asia/Novosibirsk

# Пользователь SSH
adduser --uid sshuser
echo "sshuser:P@ssw0rd" | chpasswd
echo "sshuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers
usermod -aG wheel sshuser

# SSH настройка
touch /etc/banner 
echo "
#######################
#Authorized access only
####################### " >/etc/banner 

sed -i 's/#Port 22/Port 2024/g' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
echo "Banner /etc/banner" > /etc/ssh/sshd_config
echo "AllowUsers sshuser" > /etc/ssh/sshd_config
systemctl restart sshd
