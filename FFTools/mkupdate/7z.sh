#!/bin/bash
set -e


usage()
{
cat << EOF
usage:
    $(basename $0) [-n update_img_name] [-l lunch] 
    -l: lunch name when make android

example:
    ./FFTools/mkupdate/7z.sh -l rk3568_firefly_aioj-userdebug

NOTE: Run in the path of SDKROOT
EOF

if [ ! -z $1 ] ; then
    exit $1
fi
}


USER_LUNCH="rk3568_firefly_aioj-userdebug"

while getopts "h:l:" arg
do
    case $arg in
         l)
            USER_LUNCH=$OPTARG
            ;;
         h)
            usage 0
            ;;
         ?) 
            usage 1
            ;;
    esac
done

. build/envsetup.sh >/dev/null && setpaths
if [ ! -z "$USER_LUNCH" ] ; then
    lunch "$USER_LUNCH"
fi

TARGET_PRODUCT=`get_build_var TARGET_PRODUCT`
IMAGE_SRC_CUR_PATH=rockdev/Image-$TARGET_PRODUCT

OPT_CODENAME="Android"
IMG_DIR_NAME=""
IMG_7Z_NAME=""

pushd $IMAGE_SRC_CUR_PATH

for IMG in *${OPT_CODENAME}*.img; do
    IMG_7Z=${IMG%.*}.7z
    if [ -f ${IMG_7Z} ] && [ -f ${IMG_7Z}.md5sum ];then
        echo "${IMG_7Z} is Exist"
        continue
    else
        rm -f $IMG_7Z
    fi

    if [ ! -f ${IMG} ] ; then
        echo "Not IMG Packing"
    else
        IMG_7Z_NAME=$IMG_7Z
        IMG_DIR_NAME=${IMG%.*}   
    fi
    break
done

if [ -n "$IMG_7Z_NAME" ] ; then
    if [ -d "$IMG_DIR_NAME" ] ; then
        rm -rf $IMG_DIR_NAME
    fi

    mkdir $IMG_DIR_NAME $IMG_DIR_NAME/windows $IMG_DIR_NAME/linux
    cp ../../RKTools/windows/AndroidTool/RKDevTool_Release*.zip $IMG_DIR_NAME/windows
    cp ../../RKTools/windows/DriverAssitant*.zip $IMG_DIR_NAME/windows
    cp ../../RKTools/linux/Linux_Upgrade_Tool/Linux_Upgrade_Tool*.zip $IMG_DIR_NAME/linux
    cp $IMG_DIR_NAME.img $IMG_DIR_NAME

    echo Compressing $IMG...
    7zr a -t7z -m0=lzma2 -mx=9 -mfb=64 -md=64m -ms=on -mmt=on $IMG_7Z_NAME $IMG_DIR_NAME \
        && ls -lh $IMG_7Z_NAME \
        && md5sum $IMG_7Z_NAME >$IMG_7Z_NAME.md5sum

    rm -rf $IMG_DIR_NAME
fi
