#/bin/sh
if [ -z "$BLOCK_DEVICE" ]; then
	logger "BLOCK_DEVICE is not specified in disk-formatter"
	exit 1;
fi
SWAP_GB=8
TEST=0
SECTOR_SIZE=`cat /sys/block/$BLOCK_DEVICE/queue/hw_sector_size`
SECTOR_CT=`cat /sys/block/$BLOCK_DEVICE/size`
SWAP_SECTORS=$(echo "($SWAP_GB * 1024 * 1024 * 1024) / $SECTOR_SIZE" | bc )
FREE_SECTORS=$(echo "$SECTOR_CT - ($SWAP_SECTORS + 2048)" | bc )
FREE_START=$(expr 2048 + $SWAP_SECTORS)
PARTITIONS=$(cat <<EOF
unit: sectors
/dev/$BLOCK_DEVICE1 : start=  $FREE_START, size=$FREE_SECTORS, Id=83, bootable
/dev/$BLOCK_DEVICE2 : start=        2048, size=  $SWAP_SECTORS, Id=82
/dev/$BLOCK_DEVICE3 : start=        0, size=        0, Id= 0
/dev/$BLOCK_DEVICE4 : start=        0, size=        0, Id= 0
EOF
)
echo $SWAP_SECTORS
echo $FREE_SECTORS
echo "$PARTITIONS"
if [ "$TEST" -ne 1 ]; then
	echo "$PARTITIONS" | sfdisk /dev/$BLOCK_DEVICE
fi
