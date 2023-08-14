#!/bin/bash

set -e 
SCRIPT_PATH=${MKUPDATE_PATH}/multidevices_boot
IMAGE_PATH=${SDK_ROOT}/${IMAGE_PATH}

#make idblock  bin
cd ${SDK_ROOT}/u-boot/
if [[ "$USER_LUNCH" =~ "rk3568" ]];then
    ./make.sh --idblock ../rkbin/RKBOOT/RK3568MINIALL.ini
elif [[ "$USER_LUNCH" =~ "rk3566" ]];then
    ./make.sh --idblock ../rkbin/RKBOOT/RK3566MINIALL.ini
fi
if [ $? -eq 0 ]; then
    echo "Build idblock ok!"
    cd - >/dev/null
else
    echo "Build idblock failed!"
    cd - >/dev/null
    exit 1
fi

#package raw file
mv ${SDK_ROOT}/u-boot/idblock.bin ${IMAGE_PATH}
cp ${SCRIPT_PATH}/parameter_for_multidevices_boot.txt  ${IMAGE_PATH}
cp ${SCRIPT_PATH}/raw_gpt.sh  ${IMAGE_PATH}
cd ${IMAGE_PATH}
chmod 777 raw_gpt.sh
source raw_gpt.sh
ret=$?
rm idblock.bin
rm parameter_for_multidevices_boot.txt
rm raw_gpt.sh
if [ "$ret" -eq 0 ]; then
    echo "Build raw_gpt img successfully"
    cd - >/dev/null
else
    echo "Build raw_gpt img failed!"
    cd - >/dev/null
    exit 1
fi

#rename raw_gpt.img 
if [ -z "$UPDATE_USER_NAME" ] ; then
    if [[ "${PRODUCT_MODEL}" =~ "3566" ]];then
        UPDADE_NAME="Station_M2_Android_${TARGET_VERSION}_GPT_RAW_$(date -d today +%Y%m%d)"
    elif [[ "${PRODUCT_MODEL}" =~ "3568" ]];then
        UPDADE_NAME="Station_P2_Android_${TARGET_VERSION}_GPT_RAW_$(date -d today +%Y%m%d)"
    fi

    if [ ! -z "$IMAGE_TYPE" ] ; then
        UPDADE_NAME=${IMAGE_TYPE}_${UPDADE_NAME}
    fi
else
    UPDADE_NAME="$UPDATE_USER_NAME"
fi
if [ ! -z "$IMAGE_PATH" ] ; then
    if [ -f ${IMAGE_PATH}/raw_gpt.img ]; then
        echo "rename ${IMAGE_PATH}/raw_gpt.img to ${IMAGE_PATH}/${UPDADE_NAME}.img"
        mv ${IMAGE_PATH}/raw_gpt.img ${IMAGE_PATH}/${UPDADE_NAME}.img
    fi
fi
