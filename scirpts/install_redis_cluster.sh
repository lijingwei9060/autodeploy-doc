#! /bin/sh
#######################
# REDISDATAPATH: REDIS数据路径
# REDISNODE: 每台机器上redis节点数量
# REDISSERVER: redis服务器数量
# REDISVERSION: redis 版本4.0.11,3.2.12
# REDISURL：s3安装路径，例如http://169.254.169.254:8683/bingoinstall/redis-4.0.11.zip
#######################
echo "设置host文件"
echo "${outputs.redis.privateIp}    "  `hostname` >>/etc/hosts

if [[ -f /etc/redhat-release ]]; then
  ver0="$(cat /etc/redhat-release |awk -Frelease '{print $2}' |awk '{print $1}')"
  ver="$(echo ${ver0%%.*})"
  if [ "$ver" = "7" ]; then
    Release="rhel7"
  elif [ "$ver" = "6" ]; then
    Release="rhel6"
  else
    echo "不支持的操作系统，需要使用centos或者rhel6、7版本"
    exit 1
  fi
else
    echo "不支持的操作系统，需要使用centos或者rhel6、7版本"
    exit 1
fi

echo "修改内核文件"
cat <<EOF >/etc/sysctl.d/97-redis-sysctl.conf
net.ipv4.tcp_syncookies = 0
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_synack_retries = 3
net.ipv4.tcp_syn_retries = 3
net.ipv4.tcp_rfc1337 = 1
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.conf.all.log_martians = 1
net.ipv4.tcp_ecn = 0
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 1
net.ipv4.tcp_dsack = 1
net.ipv4.ip_forward = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_max_syn_backlog = 20000
net.ipv4.tcp_orphan_retries = 1
net.ipv4.tcp_fin_timeout = 20
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 2500
net.core.somaxconn = 65000
EOF

# Reload the networking settings
/sbin/sysctl -p /etc/sysctl.d/97-redis-sysctl.conf

echo "下载redis进行安装"
wget -q ${REDISURL} -O redis-${REDISVERSION}.zip
unzip -q redis-${REDISVERSION}.zip
yum  install wget scl make gcc tcl -y
cd redis-${REDISVERSION}
yum install -y ./$Release/*.rpm
tar -xzf redis-${REDISVERSION}.tar.gz && cd redis-${REDISVERSION} && make install && cp ./src/redis-trib.rb /usr/local/bin/

echo "修改redis.conf"
sed -i "s/^bind 127.0.0.1$//g" redis.conf
sed -i "s/^protected-mode.*$/protected-mode no/g" redis.conf
sed -i "s/^# cluster-enabled yes$/cluster-enabled yes/" redis.conf
sed -i "s/^appendonly no$/appendonly yes/" redis.conf
echo "修改install_server.sh，不默认启动"
sed -i 's/^\/etc\/init.d.*/#&/' ./utils/install_server.sh


for i in $(seq ${REDISNODE}) ; do  echo $[$i+6349] ; 
    mkdir -p ${REDISDATAPATH}/$[$i+7000]
	if [[ "${REDISVERSION}" == 4.* ]] ; then 
		REDIS_PORT=$[$i+7000] REDIS_CONFIG_FILE=/etc/redis/$[$i+7000].conf REDIS_LOG_FILE=/var/log/redis_$[$i+7000].log REDIS_DATA_DIR=${REDISDATAPATH}/$[$i+7000] REDIS_EXECUTABLE=/usr/local/bin/redis-server ./utils/install_server.sh
	elif [[ "${REDISVERSION}" == 3.* ]] ; then 
		echo -e "$[$i+7000]\n/etc/redis/$[$i+7000].conf\n/var/log/redis_$[$i+7000].log\n${REDISDATAPATH}/$[$i+7000]\n/usr/local/bin/redis-server\n/usr/local/bin/redis-cli\r" | ./utils/install_server.sh
	fi
    sed -i "s/^# cluster-config-file.*$/cluster-config-file nodes-$[$i+7000].conf/" /etc/redis/$[$i+7000].conf
    /etc/init.d/redis_$[$i+7000] start
done

#------------------------------------------------------
echo "启用ruby2.4"
source /opt/rh/rh-ruby24/enable
cd redis-${REDISVERSION}
gem install -l redis-*.gem
ipstr="${outputs.multi.redis.privateIp}"
ipstr=${ipstr#[}
ipstr=${ipstr%]}
ipstr=(${ipstr//,/ })

for ips in ${ipstr[@]}; do
  for i in $(seq ${REDISNODE}); do 
    cips="$cips $ips:$[$i+7000]"
  done
done

echo "创建集群$cips"
echo "yes" | /usr/local/bin/redis-trib.rb create --replicas 1 $cips