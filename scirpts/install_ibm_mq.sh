#! /bin/sh
#######################
# MQURL：s3路径，例如http://169.254.169.254:8683/bingoinstall/WS_MQ_V8.0.0.4_LINUX_ON_X86_64_IM.tar.gz
#######################
echo "安装依赖软件包"
yum install glibc.i686 glibc.x86_64 libstdc++.i686  libstdc++.x86_64 -y 
echo "创建用户mqm"
groupadd -g 300 mqm
useradd -u 300 -g mqm -m -d /home/mqm mqm
echo "创建mqm所需目录"
mkdir /usr/mqm   
mkdir /var/mqm

echo "下载mq软件包"
wget -q ${MQURL} -O WS_MQ_V8.0.0.4_LINUX_ON_X86_64_IM.tar.gz
echo "解压mq软件包"
tar -xzf WS_MQ_V8.0.0.4_LINUX_ON_X86_64_IM.tar.gz
echo "安装MQ"
cd MQServer 
./mqlicense.sh -accept -text_only
yum install  MQSeries*.rpm -y 
cp -f PreReqs/axis/axis.jar /opt/mqm/java/lib/soap/axis.jar
chown mqm:mqm /opt/mqm/java/lib/soap/axis.jar
chmod 444 /opt/mqm/java/lib/soap/axis.jar
echo "安装完成"