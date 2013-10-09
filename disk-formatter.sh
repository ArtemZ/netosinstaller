#/bin/sh
SWAP_GB=8
TEST=0
SECTOR_SIZE=`cat /sys/block/sda/queue/hw_sector_size`
SECTOR_CT=`cat /sys/block/sda/size`
SWAP_SECTORS=$(echo "($SWAP_GB * 1024 * 1024 * 1024) / $SECTOR_SIZE" | bc )
FREE_SECTORS=$(echo "$SECTOR_CT - ($SWAP_SECTORS + 2048)" | bc )
FREE_START=$(expr 2048 + $SWAP_SECTORS)
PARTITIONS=$(cat <<EOF
unit: sectors
/dev/sda1 : start=  $FREE_START, size=$FREE_SECTORS, Id=83, bootable
/dev/sda2 : start=        2048, size=  $SWAP_SECTORS, Id=82
/dev/sda3 : start=        0, size=        0, Id= 0
/dev/sda4 : start=        0, size=        0, Id= 0
EOF
)
echo $SWAP_SECTORS
echo $FREE_SECTORS
echo "$PARTITIONS"
if [ TEST -ne 1 ]; then
	echo "$PARTITIONS" | sfdisk /dev/sda
fi
