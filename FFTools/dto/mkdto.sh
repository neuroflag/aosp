#!/bin/bash

# 使用 在SDK路径下，输入命令
# ./FFTools/dto/mkdto.sh rk3568_firefly_roc_pc-userdebug
# 用其他产品就，把 rk3568_firefly_roc_pc-userdebug 换成对应的产品

source build/envsetup.sh
lunch $1

FSTAB_TOOLS="./FFTools/dto/fstab_tools"
DTC="./FFTools/dto/dtc"
MKDT="./FFTools/dto/mkdtimg"
output_dir="./out/mkdtbo/"
output_file=$output_dir"dtbo.img"

get_build_var PRODUCT_DTBO_TEMPLATE > file_tmp
index=0
for line in $(<file_tmp)
do
    echo source_file : ./$line
    in_file[$index]=./$line
    tmp=`expr $index + 1`
    index=$tmp
done
rm file_tmp

str1="wait"
str2=${str1}
get_build_var BOARD_USES_AB_IMAGE > file_tmp
tmp="$(cat file_tmp)"
echo BOARD_USES_AB_IMAGE:[${tmp}]
if [ "$tmp" = "true" ];then
str2=${str1},slotselect
str1=${str2}
fi
rm file_tmp

get_build_var BOARD_AVB_ENABLE > file_tmp
tmp="$(cat file_tmp)"
echo BOARD_AVB_ENABLE:[${tmp}]
if [ "$tmp" = "true" ];then
str2=${str1},avb
fi
rm file_tmp

dtbo_flags=${str2}
echo dtbo_flags:[${dtbo_flags}]

get_build_var PRODUCT_BOOT_DEVICE > file_tmp
str1="$(cat file_tmp)"
if [ ! -n "${str1}"  ];then
dtbo_boot_device="none"
else
dtbo_boot_device=${str1}
fi
echo dtbo_boot_device:[${dtbo_boot_device}]
rm file_tmp

length=${#in_file[@]}

rm -r ${output_dir}*
if [ ! -d $output_dir ]; then
    mkdir $output_dir
fi

index=0
while(( $index<$length ))
do
    str1=${in_file[index]}
    str2=${str1##*/}
    str1=${str2%.*}
    str2=$str1".dts"
    str1=$output_dir$str2
    dts_file[index]=$str1
    let "index++"
done

index=0
while(( $index<$length ))
do
    ${FSTAB_TOOLS} -I dts -i ${in_file[$index]} -p ${dtbo_boot_device} -f ${dtbo_flags} -o ${dts_file[index]}
    let "index++"
done

index=0
while(( $index<$length ))
do
    str1=${dts_file[index]}
    str2=${str1%.*}
    str1=$str2".dtbo"
    dtbo_file[index]=$str1
    $DTC -@ -O dtb -o ${dtbo_file[index]} ${dts_file[index]}
    let "index++"
done

$MKDT create $output_file \
--id=/:id \
--rev=/:rev \
--custom0=/:custom0 \
--custom1=/:custom1 \
--custom2=/:custom2 \
--custom3=/:custom3 \
${dtbo_file[@]}

if [ -e $output_file ]; then
echo dtbo.img create success
else
echo dtbo.img create fail
fi

