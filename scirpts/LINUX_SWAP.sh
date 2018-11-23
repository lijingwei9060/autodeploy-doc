#! /bin/sh
#######################
# SWAPFILE:swapfile路径
# SWAPSIZE：swap文件大小，单位为Mb，auto为自动计算大小
#           规则：最小500M，最大8Gb，中间4G，等于内存大小
######################

memsize=`cat /proc/meminfo|grep MemTotal|awk '{print $2}'`
memsize=$[ memsize/1024 ]
swapsizeold=`cat /proc/meminfo|grep SwapTotal|awk '{print $2}'`
swapsizeold=$[ swapsizeold/1024 ]
swapsize=0

if [ "${SWAPSIZE}" != "AUTO" ]; then
  swapsize=${SWAPSIZE}
else
  if [ ${memsize} -gt 6144 ]; then
    swapsize=8192
  elif [ ${memsize} -gt 2048 ]; then
    swapsize=4096
  else
    swapsize=512
  fi
fi

echo -e '\n initing swap,maybe take a long time, plase wait...'
fallocate -l ${swapsize}m ${SWAPFILE}
chmod 600 ${SWAPFILE}
mkswap ${SWAPFILE}
swapon ${SWAPFILE}

fstab=/etc/fstab
grep -q "SWAPFILE##" "$fstab";

if [ $? -eq 1 ]; then
    echo "#SWAPFILE##" >> /etc/fstab
    echo "${SWAPFILE} swap swap defaults 0 0" >> /etc/fstab
else
  echo "swapfile in fstab exists."
fi