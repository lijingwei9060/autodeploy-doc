#! /bin/sh
#######################
# ORACLEUSER: oracle用户
# ORACLEPATH: oracle安装路径
# ORACLE_VERSION: oracle安装版本，12.2.0.1，12.1.0.2
# INSTALLER_S3_BUCKET：s3路径，例如http://169.254.169.254:8683/bingoinstall
#######################
echo "127.0.0.1  `hostname`" >> /etc/hosts
echo "oracle客户端需要swap分区"
echo "安装oracle需要依赖的软件包"
yum install unzip bc binutils compat-libcap1.x86_64 compat-libstdc++-33.x86_64 glibc glibc-devel ksh libaio libaio-devel libgcc libstdc++ libstdc++-devel libxcb libX11 libXau libXi libXtst libXrender make net-tools nfs-utils smartmontools sysstat -y
echo "创建用户"
groupadd -g 10001 oinstall
useradd -u 12002 -g oinstall ${ORACLEUSER}

mkdir -p ${ORACLEPATH}/install
mkdir -p ${ORACLEPATH}/app/oracle/product/12c
mkdir -p ${ORACLEPATH}/app/oraInventory
chown -R ${ORACLEUSER}:oinstall ${ORACLEPATH}/install
chown -R ${ORACLEUSER}:oinstall ${ORACLEPATH}/app/oraInventory
chown -R ${ORACLEUSER}:oinstall ${ORACLEPATH}/app/oracle/product/12c


echo "下载oracle安装文件"
if [[ '${ORACLE_VERSION}' == '12.1.0.2' ]]; then
  wget -q ${INSTALLER_S3_BUCKET}/linuxamd64_12102_client.zip -O ${ORACLEPATH}/install/linuxamd64_12102_client.zip
fi
if [[ '${ORACLE_VERSION}' == '12.2.0.1' ]]; then
  wget -q ${INSTALLER_S3_BUCKET}/linuxx64_12201_client.zip -O ${ORACLEPATH}/install/linuxx64_12201_client.zip
fi
chown -R ${ORACLEUSER}:oinstall ${ORACLEPATH}/install

echo "解压环境"
if [[ '${ORACLE_VERSION}' == '12.1.0.2' ]]; then
  su -c 'cd ${ORACLEPATH}/install && unzip -q linuxamd64_12102_client.zip && rm -rf linuxamd64_12102_client.zip'   - ${ORACLEUSER}
fi
if [[ '${ORACLE_VERSION}' == '12.2.0.1' ]]; then
    su -c 'cd ${ORACLEPATH}/install && unzip -q linuxx64_12201_client.zip && rm -rf linuxx64_12201_client.zip'   - ${ORACLEUSER}
fi

echo "安装oracle客户端"
if [[ '${ORACLE_VERSION}' == '12.1.0.2' ]]; then
su -c 'cd ${ORACLEPATH}/install/client && ./runInstaller -silent  -ignoreSysPrereqs -ignorePrereq -waitForCompletion \
FROM_LOCATION=${ORACLEPATH}/install/client/stage/products.xml \
UNIX_GROUP_NAME=oinstall \
INVENTORY_LOCATION=${ORACLEPATH}/app/oraInventory   \
ORACLE_HOME=${ORACLEPATH}/app/oracle/product/12c \
ORACLE_HOME_NAME=OraClient122_Home1 \
ORACLE_BASE=${ORACLEPATH}/app/oracle \
oracle.install.client.installType=Administrator'  - ${ORACLEUSER}
su -c 'rm -rf cd ${ORACLEPATH}/install/client'  - ${ORACLEUSER}
fi

if [[ '${ORACLE_VERSION}' == '12.2.0.1' ]]; then
su -c 'cd ${ORACLEPATH}/install/client && ./runInstaller -silent  -ignoreSysPrereqs -ignorePrereq -waitForCompletion \
FROM_LOCATION=${ORACLEPATH}/install/client/stage/products.xml \
UNIX_GROUP_NAME=oinstall \
INVENTORY_LOCATION=${ORACLEPATH}/app/oraInventory   \
ORACLE_HOME=${ORACLEPATH}/app/oracle/product/12c \
ORACLE_HOME_NAME=OraClient122_Home1 \
ORACLE_BASE=${ORACLEPATH}/app/oracle \
oracle.install.client.installType=Administrator'  - ${ORACLEUSER}
su -c 'rm -rf cd ${ORACLEPATH}/install/client'  - ${ORACLEUSER}
fi

${ORACLEPATH}/app/oraInventory/orainstRoot.sh

echo "配置oracle用户环境变量"
su -c 'cat <<"EOF" >>/home/${ORACLEUSER}/.bash_profile
export ORACLE_BASE=${ORACLEPATH}/app/oracle
export ORACLE_HOME=${ORACLEPATH}/app/oracle/product/12c/
export PATH=.:$ORACLE_HOME/bin:$ORACLE_HOME/OPatch:$ORACLE_HOME/jdk/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH
export CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib
EOF'  - ${ORACLEUSER}