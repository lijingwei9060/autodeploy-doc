#! /bin/sh
#######################
# USERNAME: tuxedo安装用户
# USERGROUP: tuxedo安组装用户
# TUXEDOPATH: tuxedo安装路径，确保有空间
# TUXEDOPASSWD: tuxedo监听密码
# TUXEDOURL: tuxedo安装文件路径
# TUXEDOVERSION: tuxedo安装版本，现在支持12.2.2.0.0，12.1.3.0.0
# PATCHURL: patch补丁地址
#######################
export LC_ALL=en_US.UTF-8
echo "添加用户${USERNAME}" 
groupadd ${USERGROUP}
useradd -m -g ${USERGROUP} ${USERNAME}

echo "优化内核参数"
cat <<EOF >/etc/sysctl.conf
vm.swappiness = 10
vm.vfs_cache_pressure = 50
fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.shmall = 1073741824
kernel.shmmax = 4398046511104
kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
EOF

echo "设置用户资源使用限制"
cat <<EOF >>/etc/security/limits.conf
${USERNAME}} soft nproc 2047
${USERNAME} hard nproc 16384
${USERNAME} soft nofile 1024
${USERNAME} hard nofile 65536
${USERNAME} soft stack 10240   
${USERNAME} hard stack 32768     
EOF

echo "安装依赖软件，使用tuxedo需要编译工具"
mkdir -p ${TUXEDOPATH}/tuxedo
chown -R ${USERNAME}:${USERGROUP} ${TUXEDOPATH}/tuxedo
yum -y install zip gcc automake autoconf libtool make 
echo "生成静默安装文件" 
su -c 'cat <<EOF >${TUXEDOPATH}/tuxedo/tuxedo.rsp
RESPONSEFILE_VERSION=2.2.1.0.0
UNIX_GROUP_NAME="${USERGROUP}"
FROM_LOCATION="${TUXEDOPATH}/tuxedo/Disk1/stage/products.xml"
ORACLE_HOME="${TUXEDOPATH}/tuxedo/oracle/tuxHome"
ORACLE_HOME_NAME="tuxHome"
SHOW_WELCOME_PAGE=true
SHOW_CUSTOM_TREE_PAGE=true
SHOW_COMPONENT_LOCATIONS_PAGE=true
SHOW_SUMMARY_PAGE=true
SHOW_INSTALL_PROGRESS_PAGE=true
SHOW_REQUIRED_CONFIG_TOOL_PAGE=true
SHOW_CONFIG_TOOL_PAGE=true
SHOW_RELEASE_NOTES=true
SHOW_ROOTSH_CONFIRMATION=true
SHOW_END_SESSION_PAGE=true
SHOW_EXIT_CONFIRMATION=true
NEXT_SESSION=false
NEXT_SESSION_ON_FAIL=true
DEINSTALL_LIST={"Tuxedo","${TUXEDOVERSION}"}
SHOW_DEINSTALL_CONFIRMATION=true
SHOW_DEINSTALL_PROGRESS=true
CLUSTER_NODES={}
ACCEPT_LICENSE_AGREEMENT=false
TOPLEVEL_COMPONENT={"Tuxedo","${TUXEDOVERSION}"}
SHOW_SPLASH_SCREEN=true
SELECTED_LANGUAGES={"en"}
COMPONENT_LANGUAGES={"en"}
INSTALL_TYPE="Full Install"
ENABLE_TSAM_AGENT=true
TLISTEN_PORT="3050"
TLISTEN_PASSWORD="${TUXEDOPASSWD}"
EOF' - ${USERNAME}
echo "下载软件包" ${TUXEDOURL} 到 ${TEMPATH}
su -c "export LC_ALL=en_US.UTF-8 ; wget -q ${TUXEDOURL} -O ${TUXEDOPATH}/tuxedo/tuxedo.zip" - ${USERNAME}
echo "生成oraInst.loc文件"
cat <<EOF >/etc/oraInst.loc
inventory_loc=/home/${USERNAME}/oraInventory
inst_group=${USERGROUP}
EOF

chmod 644 /etc/oraInst.loc
if [[ '${TUXEDOVERSION}' == '12.2.2.0.0' ]]  ; then 
echo "安装tuxedo" 到 ${TUXEDOPATH}/tuxedo
su -c "export LC_ALL=en_US.UTF-8 ; cd ${TUXEDOPATH}/tuxedo && \
      jar xf tuxedo.zip && \
      cd ${TUXEDOPATH}/tuxedo/Disk1/install &&  chmod -R +x * && ./runInstaller.sh -responseFile ${TUXEDOPATH}/tuxedo/tuxedo.rsp -silent -waitforcompletion && \
      rm -rf ${TUXEDOPATH}/tuxedo/Disk1 ${TUXEDOPATH}/tuxedo/tuxedo.rsp ${TUXEDOPATH}/tuxedo/tuxedo.zip" - ${USERNAME}
fi

if [[ '${TUXEDOVERSION}' == '12.1.3.0.0' ]] ; then 
echo "安装tuxedo" 到 ${TUXEDOPATH}/tuxedo
su -c "export LC_ALL=en_US.UTF-8 ; cd ${TUXEDOPATH}/tuxedo && \
      jar xf tuxedo.zip && \
      cd ${TUXEDOPATH}/tuxedo/Disk1/install &&  chmod -R +x * && ./runInstaller -responseFile ${TUXEDOPATH}/tuxedo/tuxedo.rsp -silent -waitforcompletion && \
      rm -rf ${TUXEDOPATH}/tuxedo/Disk1 ${TUXEDOPATH}/tuxedo/tuxedo.rsp ${TUXEDOPATH}/tuxedo/tuxedo.zip" - ${USERNAME}
fi

echo "配置用户环境变量"
su -c 'cat <<EOF>>~/.bash_profile
export ORACLE_HOME=${TUXEDOPATH}/tuxedo/oracle/tuxHome
export TUXDIR=${TUXEDOPATH}/tuxedo/oracle/tuxHome/tuxedo${TUXEDOVERSION}
export PATH=${TUXDIR}/tuxedo/bin:$PATH:$HOME/bin
EOF' - ${USERNAME}

echo "tuxedo安装完成"

if [ -n "${PATCHURL}" ]; then 
  echo "开始安装tuxedo补丁包"
  su -c "export LC_ALL=en_US.UTF-8 ; cd ${TUXEDOPATH}/tuxedo && \
         wget ${PATCHURL} -O ${TUXEDOPATH}/tuxedo/patch.zip && \
         unzip patch.zip -d ./patch/ && \
         $ORACLE_HOME/OPatch/opatch apply patch/*.zip && \
         rm -rf ${TUXEDOPATH}/tuxedo/patch.zip && \
         rm -rf ${TUXEDOPATH}/tuxedo/patch
        " - ${USERNAME}
fi

echo "编译并配置simpapp用例"
su -c "mkdir -p ${TUXEDOPATH}/tuxedo/oracle/user_projects/simpapp" - ${USERNAME}

su -c 'cat >${TUXEDOPATH}/tuxedo/oracle/user_projects/simpapp/setenv.sh << EndOfFile
source  ${TUXEDOPATH}/tuxedo/oracle/tuxHome/tuxedo${TUXEDOVERSION}/tux.env
export HOSTNAME=`uname -n`
export APPDIR=${TUXEDOPATH}/tuxedo/oracle/user_projects/simpapp
export TUXCONFIG=${TUXEDOPATH}/tuxedo/oracle/user_projects/simpapp/tuxconfig
export IPCKEY=112233
export NLSPORT=12233
export JMXPORT=22233
EndOfFile' - ${USERNAME}

echo "生成simapp的环境配置"
su -c 'cat >${TUXEDOPATH}/tuxedo/oracle/user_projects/simpapp/ubbsimple << EndOfFile
*RESOURCES
IPCKEY		112233
DOMAINID	simpapp
MASTER		site1
MAXACCESSERS	50
MAXSERVERS	20
MAXSERVICES	10
MODEL		SHM
LDBAL		Y
*MACHINES
"`uname -n`"	LMID=site1
		APPDIR="${TUXEDOPATH}/tuxedo/oracle/user_projects/simpapp"
		TUXCONFIG="${TUXEDOPATH}/tuxedo/oracle/user_projects/simpapp/tuxconfig"
		TUXDIR="${TUXEDOPATH}/tuxedo/oracle/tuxHome/tuxedo${TUXEDOVERSION}"
*GROUPS
APPGRP		LMID=site1 GRPNO=1 OPENINFO=NONE
*SERVERS
simpserv	SRVGRP=APPGRP SRVID=1 CLOPT="-A"
*SERVICES
TOUPPER
EndOfFile'  - ${USERNAME}

echo "拷贝simapp源码文件"

su -c 'if [ ! -r ${TUXEDOPATH}/tuxedo/oracle/user_projects/simpapp/simpcl.c ]; then cp ${TUXEDOPATH}/tuxedo/oracle/tuxHome/tuxedo${TUXEDOVERSION}/samples/atmi/simpapp/simpcl.c ${TUXEDOPATH}/tuxedo/oracle/user_projects/simpapp/ ; fi'  - ${USERNAME}
su -c 'if [ ! -r ${TUXEDOPATH}/tuxedo/oracle/user_projects/simpapp/simpserv.c ]; then	cp ${TUXEDOPATH}/tuxedo/oracle/tuxHome/tuxedo${TUXEDOVERSION}/samples/atmi/simpapp/simpserv.c ${TUXEDOPATH}/tuxedo/oracle/user_projects/simpapp/ ; fi'  - ${USERNAME}
 
echo "编译simapp"
su -c 'cd ${TUXEDOPATH}/tuxedo/oracle/user_projects/simpapp && \
       source setenv.sh &&  \
       tmloadcf -y ubbsimple && \
       buildclient -o simpcl -f simpcl.c && \
       buildserver -o simpserv -f simpserv.c -s TOUPPER && \
       tmboot -y && \
       ./simpcl "If you see this message, simpapp ran OK" && \
       tmshutdown -y '  - ${USERNAME}
echo "tuxedo安装完成"