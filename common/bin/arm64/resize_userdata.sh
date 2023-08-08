#set -x
partitions_num="13 12 11 10"
metadata_size_mb="16.0"

backup_size_sectors=`printf %d 0x000c0000`
cache_size_sectors=`printf %d 0x000c0000`
metadata_size_sectors=`printf %d 0x00008000`
userdata_size_sectors=`printf %d 0x0`

backup_partnum=10
cache_partnum=11
metadata_partnum=12
userdata_partnum=13

LOG(){

	#busybox echo ---firefly: $* ---
	return
}

RESIZE_PARTTITION(){
	busybox chmod 777 /sbin/sgdisk

	# wait  metadata for 5 seconds
	int=1
	while true
	do
		if busybox [ -e "/dev/block/by-name/metadata" ];then
        	metadata_block_name=`busybox ls -ld "/dev/block/by-name/metadata" | busybox awk '{print $NF}'`
			break
		else
			sleep 1
			let int++
		fi
		if busybox [ "${int}" -eq "10" ];then
			LOG "dont have sub metadata parttion"
			exit -1
		fi
	done

	# get  main block
	main_block="none"
	result=$(busybox echo ${metadata_block_name} | busybox grep "mmcblk")
	if busybox [ "${result}" != "" ];then
		LOG "multi boot on  mmc device"
		main_block="mmcblk"
	else
		result=$(busybox echo ${metadata_block_name} | busybox grep "sd")
		if busybox [ "${result}" != "" ];then
			LOG "multi boot on  usb or sata device"
                	main_block="sd"
		else
			result=$(busybox echo ${metadata_block_name} | busybox grep "nvme0n")
			if busybox [ "${result}" != "" ];then
			LOG "multi boot on  pcie device"
					main_block="nvme0n"
			else
				result=$(busybox echo ${metadata_block_name} | busybox grep "mmcblkloop")
				if busybox [ "${result}" != "" ];then
				LOG "multi boot on  virtual device"
						main_block="mmcblkloop"	
				else
					LOG "wrong main block"
					exit -1
				fi
			fi
		fi
	fi
	for var in $(busybox ls /dev/block/by-name/ | busybox grep ${main_block});do
		busybox echo ${metadata_block_name} | busybox grep ${var} > /dev/null
		if  busybox [ $? -eq 0 ];then
			sgdisk_block=${var}
			break
		else	
			sgdisk_block="none"
		fi
	done
	LOG "sgdisk block is ${sgdisk_block}"

	#test block device Can be manipulated
	while true
	do
		sgdisk  --print /dev/block/${sgdisk_block} > /dev/null
		block_usable=$?
		if busybox [ "${block_usable}" != "0" ];then
			LOG "block device Can't be manipulated"
			busybox sleep 1
			continue
		else 
			break
		fi
	done

	#Take metadata as an identifier
	read_uint=`sgdisk  --print /dev/block/${sgdisk_block} | busybox grep metadata  | busybox awk {'print $5'}  `
	read_size_mb=`sgdisk  --print /dev/block/${sgdisk_block} | busybox grep metadata  | busybox awk {'print $4'}  `
	if busybox [ "${read_uint}" = "MiB" ] && busybox [ "${read_size_mb}" = "16.0" ];then
			LOG "sgdisk do nothing on disk"
			return 0
	fi


	#delete partition for resize
	for val in ${partitions_num};do
	LOG "delete ${val} partition"
	sgdisk --delete ${val} /dev/block/${sgdisk_block}
	busybox sleep 0.5
	done

	#create backup partiton
	sgdisk --new ${backup_partnum}:0:+${backup_size_sectors} /dev/block/${sgdisk_block}
	sgdisk --change-name ${backup_partnum}:"backup" /dev/block/${sgdisk_block}	
	busybox sleep 0.5
	#create cache partition
	sgdisk --new ${cache_partnum}:0:+${cache_size_sectors} /dev/block/${sgdisk_block}
	sgdisk --change-name ${cache_partnum}:"cache" /dev/block/${sgdisk_block}	
	busybox sleep 0.5
	#create metadata partition
	sgdisk --new ${metadata_partnum}:0:+${metadata_size_sectors} /dev/block/${sgdisk_block}
	sgdisk --change-name ${metadata_partnum}:"metadata" /dev/block/${sgdisk_block}		
	busybox sleep 0.5
	#create userdata partition
	sgdisk --new ${userdata_partnum}:0:0 /dev/block/${sgdisk_block}
	sgdisk --change-name ${userdata_partnum}:"userdata" /dev/block/${sgdisk_block}
	
	busybox sleep 0.5
	#reprobe the partition table
	LOG "blockdev reprobe the partition"
	blockdev --rereadpt /dev/block/${sgdisk_block}
	busybox sleep 0.5
}

#busybox cat /proc/cmdline | busybox grep "storageboot.type=multiboot" > /dev/null
#if busybox [ $? -eq 0 ]
#then
RESIZE_PARTTITION

#else
#	LOG "dont boot from multidevices"
#fi

