#! /bin/sh
echo "下载JDK安装文件"
wget ${JREFILEPATH} -O jre.tar.gz

echo "安装JDK"
mkdir /usr/java -p
tar -xzf jre.tar.gz -C /usr/java
export JAVA_DIR=$(ls -1 -d /usr/java/*) && \
ln -s $JAVA_DIR /usr/java/latest && \
ln -s $JAVA_DIR /usr/java/default && \
alternatives --install /usr/bin/java java $JAVA_DIR/bin/java 20000 && \
alternatives --install /usr/bin/javac javac $JAVA_DIR/bin/javac 20000 && \
alternatives --install /usr/bin/jar jar $JAVA_DIR/bin/jar 20000 && \
alternatives --set java $JAVA_DIR/bin/java && \
alternatives --set javac $JAVA_DIR/bin/javac && \
alternatives --set jar $JAVA_DIR/bin/jar 

echo "配置环境变量"
echo "export JAVA_HOME=$JAVA_DIR" >> /etc/profile
echo "export JRE_HOME=$JAVA_DIR/jre" >> /etc/profile
echo "export PATH=$PATH:$JAVA_DIR/bin:$JAVA_DIR/jre/bin" >> /etc/profile

