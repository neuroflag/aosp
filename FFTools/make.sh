#!/bin/bash

set -e

usage()
{
cat << EOF
usage:
    $(basename $0) [-d dts_file_name] [-l lunch] [-j make_thread]
    -d: kernel dts name
    -l: lunch name when make android
    -j: make theard num, if have not this arg, default theard is 8
    
example:
    complie all  : ./FFTools/make.sh -d rk3568-firefly-aioj -j8 -l rk3568_firefly_aioj-userdebug
NOTE: Run in the path of SDKROOT
EOF

if [ ! -z $1 ] ; then
    exit $1
fi
}


BUILD_UBOOT=true
BUILD_KERNEL=true
BUILD_ANDROID=true

MAKE_THEARD=8
MAKE_MODULES=''
MAKE_ALL=true

while getopts "uabhj:d:l:" arg
do
    case $arg in
         j)
            MAKE_THEARD=$OPTARG
            ;;
         d)
            KERNEL_DTS=$OPTARG
            ;;
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

FFTOOLS_PATH=$(dirname $0)

source build/envsetup.sh
lunch $USER_LUNCH
if [ $? -eq 0 ]; then
    echo "lunch ok!"
else
    echo "lunch failed!"
    exit 1
fi

UBOOT_DEFCONFIG=`get_build_var PRODUCT_UBOOT_CONFIG`
KERNEL_ARCH=`get_build_var PRODUCT_KERNEL_ARCH`
KERNEL_DEFCONFIG=`get_build_var PRODUCT_KERNEL_CONFIG`

color_failed=$'\E'"[0;31m"
color_success=$'\E'"[0;32m"
color_reset=$'\E'"[00m"

#echo -n "${color_success}" && echo "${color_reset}"

# build uboot
if [ "$BUILD_UBOOT" = true ] ; then
echo
echo "====== start build uboot"
echo
cd u-boot

echo -n "${color_success}make clean && make mrproper && make distclean" && echo "${color_reset}"
make clean && make mrproper && make distclean

echo -n "${color_success}./make.sh $UBOOT_DEFCONFIG" && echo "${color_reset}"
./make.sh $UBOOT_DEFCONFIG --spl-new

if [ $? -eq 0 ]; then
    echo "Build uboot ok!"
    cd - >/dev/null
else
    echo "Build uboot failed!"
    cd - >/dev/null
    exit 1
fi

fi

# build kernel
if [ "$BUILD_KERNEL" = true ] ; then
echo
echo "====== start build kernel"
echo
cd kernel

echo -n "${color_success}make clean" && echo "${color_reset}"
make clean

echo -n "${color_success}make ARCH=$KERNEL_ARCH $KERNEL_DEFCONFIG" && echo "${color_reset}"
make ARCH=$KERNEL_ARCH $KERNEL_DEFCONFIG

echo -n "${color_success}make ARCH=$KERNEL_ARCH $KERNEL_DTS.img -j$MAKE_THEARD" && echo "${color_reset}"
make ARCH=$KERNEL_ARCH $KERNEL_DTS.img -j$MAKE_THEARD
if [ $? -eq 0 ]; then
    echo "Build kernel ok!"
    cd - >/dev/null
else
    echo "Build kernel failed!"
    cd - >/dev/null
    exit 1
fi

fi

# build android
if [ "$BUILD_ANDROID" = true ] ; then
echo
echo "====== start build android"
echo

echo -n "${color_success}make installclean" && echo "${color_reset}"
make installclean

echo -n "${color_success}make -j$MAKE_THEARD" && echo "${color_reset}"
make -j$MAKE_THEARD
# check the result of make
if [ $? -eq 0 ]; then
    echo "Build android ok!"
else
    echo "Build android failed!"
    exit 1
fi

# make and copy android images
echo
echo "====== make and copy android images"
echo -n "${color_success}./mkimage.sh" && echo "${color_reset}"
./mkimage.sh
if [ $? -eq 0 ]; then
    echo "Make image ok!"
else
    echo "Make image failed!"
    exit 1
fi

fi
