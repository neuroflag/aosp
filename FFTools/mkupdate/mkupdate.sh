#!/bin/bash

set -e

MULTI_DEVICES=false
SDK_ROOT=`pwd`

usage()
{
cat << EOF
usage:
    $(basename $0) [-l lunch]
    -l: lunch name when make android

example:
    ./FFTools/mkupdate/mkupdate.sh -l rk3568_firefly_aioj-userdebug
                
NOTE: Run in the path of SDKROOT
EOF

if [ ! -z $1 ] ; then
    exit $1
fi
}

while getopts "hn:l:t::g" arg
do
    case $arg in
         l)
            USER_LUNCH=$OPTARG
            ;;
		 g)
		 	MULTI_DEVICES=true
			;;
         h)
            usage 0
            ;;
         ?)
            usage 1
            ;;
    esac
done

source build/envsetup.sh >/dev/null && setpaths
if [ ! -z "$USER_LUNCH" ] ; then
    lunch "$USER_LUNCH" >/dev/null
fi

PRODUCT_FIREFLY_NAME=`get_build_var PRODUCT_FIREFLY_NAME`
PRODUCT_FIREFLY_NAME=${PRODUCT_FIREFLY_NAME:=""DEFAULT""}
#echo "PRODUCT_FIREFLY_NAME=$PRODUCT_FIREFLY_NAME"
TARGET_PRODUCT=`get_build_var TARGET_PRODUCT`
#echo -e "TARGET_PRODUCT=$TARGET_PRODUCT"
PRODUCT_MODEL=`get_build_var PRODUCT_MODEL`
#echo -e "PRODUCT_MODEL=$PRODUCT_MODEL"
TARGET_VERSION=`get_build_var PLATFORM_VERSION`
IMAGE_PATH=rockdev/Image-$TARGET_PRODUCT

#for multidevices_boot
if [ "${MULTI_DEVICES}" == "true" ];then
MKUPDATE_PATH=$(dirname "$(readlink -f "$0")")
cd ${MKUPDATE_PATH}
source ${MKUPDATE_PATH}/multidevices_boot/multidevices_boot.sh 
cd - > /dev/null
exit 0
fi

# make update.img
./build.sh -u



if [ -z "$UPDATE_USER_NAME" ] ; then
    UPDADE_NAME="${PRODUCT_MODEL}_Android${TARGET_VERSION}_${PRODUCT_FIREFLY_NAME}_$(date -d today +%y%m%d)"
    if [ ! -z "$IMAGE_TYPE" ] ; then
        UPDADE_NAME=${IMAGE_TYPE}_${UPDADE_NAME}
    fi
else
    UPDADE_NAME="$UPDATE_USER_NAME"
fi

# rename update.img
if [ ! -z "$IMAGE_PATH" ] ; then
    if [ -f ${IMAGE_PATH}/update.img ]; then
        echo "rename ${IMAGE_PATH}/update.img to ${IMAGE_PATH}/${UPDADE_NAME}.img"
        mv ${IMAGE_PATH}/update.img ${IMAGE_PATH}/${UPDADE_NAME}.img
    fi
fi

TARGET_BOARD_PLATFORM=`get_build_var TARGET_BOARD_PLATFORM`

# generate software version for factory production, different platfrom different -V/-t !!!
which ffgenswv.bin > /dev/null 2>&1 && \
ffgenswv.bin -o "${IMAGE_PATH}/ffimage.swv" -V 100 \
    -m "${PRODUCT_MODEL}" -b "${TARGET_BOARD_PLATFORM}" -u "${IMAGE_PATH}/${UPDADE_NAME}.img"
