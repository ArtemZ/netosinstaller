#!/bin/sh

#. disk_formatter.sh
#. config.sh
DISTR_SERVER=192.168.1.100
ETH0_MAC=`cat /sys/class/net/eth0/address | tr '[:upper:]' '[:lower:]' `
ETH1_MAC=`cat /sys/class/net/eth1/address | tr '[:upper:]' '[:lower:]' `
DISTR_URL="http://$DISTR_SERVER:4567/config/$ETH1_MAC?username=artemz&password=123456"
BLOCK_DEVICE=
if [ -r /dev/vda ]; then
	BLOCK_DEVICE=vda
elif [ -r /dev/sda ]; then
	BLOCK_DEVICE=sda
elif [ -r /dev/hda ]; then
	BLOCK_DEVICE=hda
fi

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

if [ "$OSNAME" == "centos6x64" ]; then
	DISTR_FILE_URL="http://$DISTR_SERVER/os/$OSNAME.tar.gz"
	DISTR_FILE_STATUS=`curl -s --head -w %{http_code} $DISTR_FILE_URL -o /dev/null`
	if [ "$DISTR_FILE_STATUS" != "200" ]; then
		logger "Error accessing distribution file: $DISTR_FILE_STATUS"
		exit 1;
	fi
	wget http://$DISTR_SERVER/installer/disk-formatter.sh -O /tmp/disk_formatter.sh
	. /tmp/disk_formatter.sh
	mkswap /dev/"$BLOCK_DEVICE"2
	mkfs.ext3 /dev/"$BLOCK_DEVICE"1
	mount /dev/"$BLOCK_DEVICE"1 /mnt
	wget $DISTR_FILE_URL -O /mnt/centos.tar.gz
	cd /; tar xzf /mnt/centos.tar.gz
	sed -i 's/IPADDR=0.0.0.0/IPADDR=$SERVER_IP/g' /mnt/etc/sysconfig/network-scripts/ifcfg-eth0
	sed -i 's/GATEWAY=0.0.0.0/SERVER_GATEWAY=$SERVER_IP/g' /mnt/etc/sysconfig/network-scripts/ifcfg-eth0
	sed -i 's/HWADDR=0.0.0.0/HWADDR=$ETH0_MAC/g' /mnt/etc/sysconfig/network-scripts/ifcfg-eth0
	grub-install.unsupported /dev/"$BLOCK_DEVICE" --root-directory=/mnt
elif [ "$OSNAME" == "win2008r2" ]; then
	#wget http://$DISTR_SERVER/os/win2008.img.gz -O- | gunzip -c | dd of=/dev/"$BLOCK_DEVICE" conv=sync,noerror bs=64K
	wget http://$DISTR_SERVER/os/win2008.img -O- > /dev/"$BLOCK_DEVICE"
	#forcing partition reload
	partprobe
	mount /dev/"$BLOCK_DEVICE"1 /mnt
	sed -i 's/<Value>SomePassword123<\/Value>/<Value>$OSPASSWORD<\/Value>/g' /mnt/Autounattend.xml
	sed -i 's/>94.242.233.61/24</<Value>$SERVER_IP<\/Value>/g' /mnt/Autounattend.xml
	sed -i 's/<NextHopAddress>94.242.221.1<\/NextHopAddress>/<NextHopAddress>$SERVER_GATEWAY<\/NextHopAddress>/g' /mnt/Autounattend.xml
else
	logger "Unknown os name: $OSNAME"
	exit 1;
fi

#Sending reinstallation report
curl -d "username=artemz&password=123456&status=true&msg=ok" http://$DISTR_SERVER:4567/reinstall/$ETH1_MAC
