#!/bin/sh

. disk_formatter.sh
. config.sh
DISTR_SERVER=server.netdedicated.ru
SERVER_MAC=`cat /sys/class/net/eth1/address`
function install_centos6_64() {
	mkswap /dev/sda2
	mkfs.ext4 /dev/sda1
	mount /dev/sda1 /mnt
	wget http://$DISTR_SERVER/centos6x64.tar.gz -O /mnt/centos.tar.gz
	cd /; tar xzf /mnt/centos.tar.gz
	sed -i 's/IPADDR=0.0.0.0/IPADDR=$SERVER_IP' /mnt/etc/sysconfig/network-scripts/ifcfg-eth0
	sed -i 's/GATEWAY=0.0.0.0/SERVER_GATEWAY=$SERVER_IP' /mnt/etc/sysconfig/network-scripts/ifcfg-eth0
	sed -i 's/HWADDR=0.0.0.0/HWADDR=$SERVER_MAC' /mnt/etc/sysconfig/network-scripts/ifcfg-eth0
	grub-install /dev/sda1 --root-directory=/mnt
}

#
# Configure internal network
# dhclient eth1 -r
# dhclient eth1


