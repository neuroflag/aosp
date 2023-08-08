#!/bin/bash
echo "$1 $2 $3 $4 $5"
TARGET_PRODUCT=$1
PRODUCT_OUT=$2
TARGET_BOARD_PLATFORM=$3
TARGET_ROCKCHIP_PCBATEST=$4
TARGET_ARCH=$5

PCBA_PATH=external/pcba_rockchip/pcba_core

############################################################################################
#rk recovery contents
############################################################################################
cp -f vendor/rockchip/common/bin/$TARGET_ARCH/resize2fs $PRODUCT_OUT/recovery/root/sbin/
cp -f vendor/rockchip/common/bin/$TARGET_ARCH/sgdisk $PRODUCT_OUT/recovery/root/sbin/
cp -f vendor/rockchip/common/bin/$TARGET_ARCH/resize_userdata.sh $PRODUCT_OUT/recovery/root/sbin/
