#!/bin/bash

zabbix_agent_conf=/etc/zabbix/zabbix_agentd.conf
rules=/etc/iptables/rules.v4

# Add GlusterFS repo
wget -O - http://download.gluster.org/pub/gluster/glusterfs/3.9/rsa.pub | apt-key add -
echo deb http://download.gluster.org/pub/gluster/glusterfs/3.9/LATEST/Debian/jessie/apt jessie main > /etc/apt/sources.list.d/gluster.list

mkdir /data/glusterfs

sed -i -e 's/Port 22/Port 38022/g' /etc/ssh/sshd_config

# Add aliases
echo "alias reload_iptables='cat $rules | sudo iptables-restore -c'" >> /home/smaslov/.bashrc
echo "alias reload_iptables='cat $rules | sudo iptables-restore -c'" >> /root/.bashrc

# Configure firewall
iptables -F
iptables -A INPUT -i lo -j ACCEPT
iptables -N zabbix
iptables -A INPUT -s 172.44.50.3/32 -j zabbix
iptables -A zabbix -p tcp --dport 10050 -j ACCEPT
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp -s 172.44.50.1/28 --dport 38022 -j ACCEPT
iptables -A INPUT -p tcp -m multiport -s 192.168.49.1/24 --dports 111,24007,24008,49152,49153 -j ACCEPT
iptables -A INPUT -j DROP

# Install packages
apt-get update
apt-get install tcpdump vim iptables-persistent lm-sensors htop iftop iotop ethtool tmux curl ifenslave zabbix-agent sudo mc fail2ban glusterfs-server -y

# Edit firewall rules
service fail2ban stop
sed -i '/fail2ban/d' $rules
cat $rules | iptables-restore -c
service fail2ban start

# Edit Zabbix agent configuration
sed -i -e 's/Server=127.0.0.1/Server=172.44.50.3/g' $zabbix_agent_conf
sed -i -e 's/ServerActive=127.0.0.1/ServerActive=172.44.50.3/g' $zabbix_agent_conf
cat <<EOF >> $zabbix_agent_conf
EnableRemoteCommands=1
UserParameter=custom.softraid.status,egrep -c "\[.*_.*\]" /proc/mdstat
UserParameter=cpu_sensor,sensors | grep Physical | cut -b18-21
EOF

# Edit hosts
cat <<EOF > /etc/hosts
127.0.0.1	localhost
192.168.49.10	gluster02.asa.local	gluster02
192.168.49.3	node01.asa.local	node01
192.168.49.4	node02.asa.local	node02
192.168.49.6	node03.asa.local	node03
192.168.49.7	node04.asa.local	node04
192.168.49.8	node05.asa.local	node05
192.168.49.9	gluster01.asa.local 	gluster01

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

# Edit ethernet
cat <<EOF > /etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback
# The primary network interface
auto bond0
iface bond0 inet dhcp
	bond_mode balance-tlb
	bond_miimon 100
	bond_downdelay 200
	bond_updalay 200
	slaves eth0 eth1
EOF

gluster peer probe 192.168.49.9
gluster volume create GlusterFS replica 2 transport tcp 192.168.49.9:/data/glusterfs 192.168.49.10:/data/glusterfs force
gluster volume start GlusterFS
gluster volume set GlusterFS auth.allow 192.168.49.0/28
gluster volume set GlusterFS network.ping-timeout "5"
