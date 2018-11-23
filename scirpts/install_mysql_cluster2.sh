#! /bin/sh
#######################
# MYSQLDATAPATH: MYSQL数据路径
# MYSQLBACKUPPATH: MYSQL备份数据路径
# MYSQLCLUSTERNAME: MYSQL集群名称
# MYSQLROOTPASSWD: MYSQL ROOT密码
# MYSQLSSTPASSWD: MYSQL SST密码
# MYSQLBACKUPKEEP: MYSQL 备份保留周期
# MYSQLURL：s3安装路径，例如http://169.254.169.254:8683/bingoinstall/mysql-5.6.40.zip
#######################
echo "设置host文件"
echo "${outputs.mysql1_instance.privateIp}    "  ${outputs.mysql1_instance.instanceCode} >>/etc/hosts
echo "${outputs.mysql2_instance.privateIp}    "  ${outputs.mysql2_instance.instanceCode} >>/etc/hosts
echo "${outputs.mysql3_instance.privateIp}    "  ${outputs.mysql3_instance.instanceCode} >>/etc/hosts

echo "下载mysql安装包"
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

wget ${MYSQLURL} -O mysql.zip 
unzip -q mysql.zip 

echo "安装mysql软件包"
yum remove -y mysql
yum install mysql/install/$Release/*.rpm -y

echo "准备mysql文件路径"
mkdir -p ${MYSQLDATAPATH}/{data,log,run,scripts}
chown -R mysql:mysql ${MYSQLDATAPATH}

echo "准备mysql配置文件"
cat <<EOF >/etc/my.cnf
[mysqld]
user=mysql
socket=${MYSQLDATAPATH}/run/mysqld.sock
pid-file=${MYSQLDATAPATH}/run/mysqld.pid
symbolic-links=0
explicit_defaults_for_timestamp=true

datadir=${MYSQLDATAPATH}/data
max_connections=1000
skip-name-resolve
sql_mode=STRICT_ALL_TABLES
collation-server=utf8_general_ci
character-set-server=utf8
skip-character-set-client-handshake

default-storage-engine=INNODB
innodb_file_per_table=1
innodb_data_home_dir=${MYSQLDATAPATH}/data
innodb_data_file_path=ibdata1:128M:autoextend
innodb_log_group_home_dir=${MYSQLDATAPATH}/data
innodb_log_file_size=256M
innodb_log_files_in_group=2
innodb_locks_unsafe_for_binlog=1
innodb_autoinc_lock_mode=2
innodb_doublewrite=1
sync_binlog=1
innodb_flush_log_at_trx_commit=2

thread_cache_size=16
innodb_buffer_pool_size=256M
tmp_table_size=128M
max_heap_table_size=64M

binlog_format=ROW
wsrep_cluster_name=${MYSQLCLUSTERNAME}
wsrep_provider=/usr/lib64/libgalera_smm.so
wsrep_sst_method=xtrabackup-v2
wsrep_sst_auth=sst:${MYSQLSSTPASSWD}
wsrep_slave_threads=16
wsrep_provider_options='pc.ignore_sb=1;gcache.size=256M;gcache.page_size=256M'
wsrep_replicate_myisam=1
slave-skip-errors=1062

wsrep_cluster_address=gcomm://${outputs.mysql1_instance.privateIp},${outputs.mysql2_instance.privateIp},${outputs.mysql3_instance.privateIp}
wsrep_node_address=${outputs.mysql2_instance.privateIp}
wsrep_node_name=${outputs.mysql2_instance.instanceCode}

[mysqld_safe]
log-error=/var/log/mysqld.log

[client]
socket=${MYSQLDATAPATH}/run/mysqld.sock
default-character-set=utf8
EOF

echo "初始化数据库"
mysql_install_db

echo "启动mysql"
service mysql start


echo "安装完成"
