#!/bin/sh

#. disk_formatter.sh
#. config.sh
DISTR_SERVER=192.168.1.100
ETH0_MAC=`cat /sys/class/net/eth0/address`
ETH1_MAC=`cat /sys/class/net/eth1/address`
DISTR_URL="http://$DISTR_SERVER:4567/config/$ETH1_MAC?username=artemz&password=123456"

wget http://$DISTR_SERVER/installer/disk-formatter.sh -O /tmp/disk_formatter.sh
. /tmp/disk_formatter.sh
#Server_IP=`ifconfig eth1|grep inet|head -1|sed 's/\:/ /'|awk '{print $3}'`
DISTR_CONFIG_STATUS=`curl -s --head -w %{http_code} $DISTR_URL -o /dev/null`
if [ "$DISTR_CONFIG_STATUS" == "403" ]; then
	logger "No access to distr server"
	exit 1;
fi
if [ "$DISTR_CONFIG_STATUS" == "404" ]; then
	logger "No configuration found for mac $ETH1_MAC"
	exit 1;
fi
if [ "$DISTR_CONFIG_STATUS" != "200" ]; then
	logger "Unknown error when access distr server: $DISTR_CONFIG_STATUS"
	exit 1;
fi

wget -O /tmp/config.sh $DISTR_URL
. /tmp/config.sh
if [ -z "$NETMASK" ]; then
	logger "Configuration for mac $ETH1_MAC was not found on distr server $DISTR_SERVER"
	exit 1;
fi
if [ -z "$OSNAME" ]; then
	logger "OSNAME is not specified in configuration"
	exit 1;
fi
DISTR_FILE_URL="http://$DISTR_SERVER/os/$OSNAME.tar.gz"
DISTR_FILE_STATUS=`curl -s --head -w %{http_code} $DISTR_FILE_URL -o /dev/null`
if [ "$DISTR_FILE_STATUS" != "200" ]; then
	logger "Error accessing distribution file: $DISTR_FILE_STATUS"
	exit 1;
fi
if [ "$OSNAME" == "centos6x64" ]; then
	install_centos6_64
fi
logger "Unknown os name: $OSNAME"
exit 1;
function install_centos6_64() {
	mkswap /dev/sda2
	mkfs.ext4 /dev/sda1
	mount /dev/sda1 /mnt
	wget $DISTR_FILE_URL -O /mnt/centos.tar.gz
	cd /; tar xzf /mnt/centos.tar.gz
	sed -i 's/IPADDR=0.0.0.0/IPADDR=$SERVER_IP' /mnt/etc/sysconfig/network-scripts/ifcfg-eth0
	sed -i 's/GATEWAY=0.0.0.0/SERVER_GATEWAY=$SERVER_IP' /mnt/etc/sysconfig/network-scripts/ifcfg-eth0
	sed -i 's/HWADDR=0.0.0.0/HWADDR=$ETH0_MAC' /mnt/etc/sysconfig/network-scripts/ifcfg-eth0
	grub-install /dev/sda1 --root-directory=/mnt
}

#
# Configure internal network
# dhclient eth1 -r
# dhclient eth1


