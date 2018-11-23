#! /bin/sh
#######################
# VOLUMEID:存储卷volume id，大小写无关
# FSTYPE：格式化磁盘文件系统类型，支持ext3、ext4、btrfs
# MOUNTPOINT: 挂载点
# NEEDREBOOT: 是否需要重启
#######################
volume=""
if [ -z "$VOLUMEID" ] || [ -z "$FSTYPE" ] || [ -z "$MOUNTPOINT" ] ;then 
  echo "请初始化参数VOLUMEID，FSTYPE，MOUNTPOINT"
  exit 1
fi

function loadVolume(){
        serial=$(grep -li "$VOLUMEID" /sys/block/vd*/serial)
        if [ -z "$serial" ] ;then 
          return
        fi
        blkpath=${serial%/*}
        volume=${blkpath##*/}
}

for i in $( seq 10);do
    loadVolume;
	echo $volume
	if [ "$volume" = "" ];then
		echo can not load volume
		sleep 5
		continue
	else
		break
	fi
done

if [ "$volume" = "" ] ;then
	if [ -f attach.error ]; then
		echo there is no avalible volume ,please check your vm.
		echo now:`date +%Y-%m-%d" "%k:%M:%S`
		exit 1
  else
		echo "${VOLUMEID} 找不到存储卷${VOLUMEID} ，机器将重启来重新加载磁盘。"
		echo "${VOLUMEID} 找不到存储卷${VOLUMEID} ，机器将重启来重新加载磁盘。" > attach.error
    if [ !${NEEDREBOOT} ] ;then 
      exit 1
    fi
		reboot
		sleep 10
	fi
else
if !(test -d ${MOUNTPOINT});then
	 mkdir -p ${MOUNTPOINT}
	echo mkdir -p ${MOUNTPOINT}
else
	echo ${MOUNTPOINT} existed
fi
	 mkfs -F -t ${FSTYPE} /dev/$volume
	 mount /dev/$volume ${MOUNTPOINT}
     echo "UUID="`blkid -o value -s UUID /dev/$volume` " ${MOUNTPOINT} ${FSTYPE}    defaults        0       0">> /etc/fstab
	echo attach volume success $volume
fi
