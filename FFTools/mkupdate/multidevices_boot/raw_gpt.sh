#!/bin/bash
set -e
rm -rf ${GPTBOOTIMG}
GPTBOOTIMG=raw_gpt.img
echo "Start making raw_gpt img!"
LOADER1_START=64
PARAMETER=parameter_for_multidevices_boot.txt
PARTITIONS=()
START_OF_PARTITION=0
PARTITION_INDEX=0


#echo "Parse the parameter file"
for PARTITION in `cat ${PARAMETER} | grep '^CMDLINE' | sed 's/ //g' | sed 's/.*:\(0x.*[^)])\).*/\1/' | sed 's/,/ /g'`; do
        PARTITION_NAME=`echo ${PARTITION} | sed 's/\(.*\)(\(.*\))/\2/' | cut -f 1 -d ":"`
        PARTITION_START=`echo ${PARTITION} | sed 's/.*@\(.*\)(.*)/\1/'`
        PARTITION_LENGTH=`echo ${PARTITION} | sed 's/\(.*\)@.*/\1/'`
        PARTITIONS+=("$PARTITION_NAME")
        PARTITION_INDEX=$(expr $PARTITION_INDEX + 1)
        eval "${PARTITION_NAME}_START_PARTITION=${PARTITION_START}"
        eval "${PARTITION_NAME}_LENGTH_PARTITION=${PARTITION_LENGTH}"
        eval "${PARTITION_NAME}_INDEX_PARTITION=${PARTITION_INDEX}"
done


GPTIMG_MIN_SIZE=`expr \( $(((${PARTITION_START} + 0x2000))) \) \* 512`
GPT_IMAGE_SIZE=`expr ${GPTIMG_MIN_SIZE} \/ 1024 \/ 1024 + 4`

#echo "Make a raw_gpt img(zero)"
dd if=/dev/zero of=${GPTBOOTIMG} bs=1M count=0 seek=$GPT_IMAGE_SIZE &>/dev/null
parted -s ${GPTBOOTIMG} mklabel gpt

for PARTITION in ${PARTITIONS[@]}; do
    PSTART=${PARTITION}_START_PARTITION
    PLENGTH=${PARTITION}_LENGTH_PARTITION
    PINDEX=${PARTITION}_INDEX_PARTITION
    PSTART=${!PSTART}
    PLENGTH=${!PLENGTH}
    PINDEX=${!PINDEX}

    if [ "${PLENGTH}" == "-" ]; then
        parted -s ${GPTBOOTIMG} --  unit s mkpart ${PARTITION} $(((${PSTART} + 0x00))) -34s &>/dev/null
    else
        PEND=$(((${PSTART} + 0x00 + ${PLENGTH})))
        parted -s ${GPTBOOTIMG} unit s mkpart ${PARTITION} $(((${PSTART} + 0x00))) $(expr ${PEND} - 1)  &>/dev/null
    fi
done
:<<!
UUID=$(cat ${PARAMETER} | grep 'uuid' | cut -f 2 -d "=")
VOL=$(cat ${PARAMETER} | grep 'uuid' | cut -f 1 -d "=" | cut -f 2 -d ":")
VOLINDEX=${VOL}_INDEX_PARTITION
VOLINDEX=${!VOLINDEX}
gdisk ${GPTBOOTIMG} <<EOF
x
c
${VOLINDEX}
${UUID}
w
y
EOF
!

#echo "Add idbblock into the raw_gpt img"
dd if=idblock.bin of=${GPTBOOTIMG} seek=64 conv=notrunc &>/dev/null

#echo "Add imgs into the raw_gpt img"
simg2img super.img super_raw.img

for PARTITION in ${PARTITIONS[@]}; do
    PSTART=${PARTITION}_START_PARTITION
    PSTART=${!PSTART}
    IMGFILE=${PARTITION}.img
    if [[ x"$IMGFILE" != x ]]; then
        if [[ -f "$IMGFILE" ]]; then
            if [[ "${IMGFILE}" =~ "super.img" ]];then
                IMGFILE="super_raw.img"
                dd if=${IMGFILE}  of=${GPTBOOTIMG} seek=$(((${PSTART} + 0x00))) conv=notrunc,fsync  &>/dev/null
                rm ${IMGFILE}
            else
                dd if=${IMGFILE}  of=${GPTBOOTIMG} seek=$(((${PSTART} + 0x00))) conv=notrunc,fsync  &>/dev/null
            fi
        else
            if [[ x"$IMGFILE" != xRESERVED ]]; then
                echo -e "\e[31m error: $IMGFILE not found! \e[0m" &>/dev/null
            fi
        fi
    fi
done
echo "Make raw_gpt img done"
