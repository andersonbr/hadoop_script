#!/bin/bash

if [ $UID != 0 ]; then
 echo executar como root.
 exit 1
fi

source /etc/profile

# env vars
export JAVA_HOME=/usr/lib/jvm/java-8-oracle/jre
export HADOOP_VERSION=3.1.0
export HADOOP_USER=hadoop
export HADOOP_GROUP=hadoop
export HADOOP_BINARY_FILE=hadoop-$HADOOP_VERSION.tar.gz
export HADOOP_BINARY_DIR=hadoop-$HADOOP_VERSION
export HADOOP_DOWNLOAD_URL=http://mirror.nbtelecom.com.br/apache/hadoop/common/hadoop-$HADOOP_VERSION/$HADOOP_BINARY_FILE
export HADOOP_HOME=$PWD/$HADOOP_BINARY_DIR

export SPARK_VERSION=2.3.1
export SPARK_BINARY_FILE=spark-$SPARK_VERSION-bin-hadoop2.7.tgz
export SPARK_BINARY_DIR=spark-$SPARK_VERSION-bin-hadoop2.7
export SPARK_DOWNLOAD_URL=http://ftp.unicamp.br/pub/apache/spark/spark-$SPARK_VERSION/$SPARK_BINARY_FILE

export HADOOP_MAPRED_HOME=$HADOOP_HOME
export HADOOP_COMMON_HOME=$HADOOP_HOME
export HADOOP_HDFS_HOME=$HADOOP_HOME
export HADOOP_YARN_HOME=$HADOOP_HOME
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop

# hdfs
export HDFS_NAMENODE_DIR=$HADOOP_HOME/hdfs/namenode
export HDFS_DATANODE_DIR=$HADOOP_HOME/hdfs/datanode
export HDFS_NAMENODE_USER=$HADOOP_USER
export HDFS_DATANODE_USER=$HADOOP_USER

export HDFS_SECONDARYNAMENODE_USER=$HADOOP_USER
export YARN_RESOURCEMANAGER_USER=$HADOOP_USER

# path
export OLDPATH=$PATH
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

# user e group
if [ $(id hadoop 2>/dev/null|wc -l) -eq 0 ]; then
  echo criando usuario $HADOOP_USER
  useradd -d $HADOOP_HOME -U $HADOOP_USER
fi

# baixar hadoop se nao existir o arquivo
if [ ! -f $HADOOP_BINARY_FILE ]; then
  echo baixando hadoop
  wget $HADOOP_DOWNLOAD_URL
fi

# descompacta hadoop
if [ ! -d $HADOOP_BINARY_DIR ]; then
  echo descompactando hadoop
  tar zxf $HADOOP_BINARY_FILE
  chown -R $HADOOP_USER:$HADOOP_GROUP $HADOOP_BINARY_DIR
  echo liberando ssh sem senha com chave publica para usuario $HADOOP_USER
  su -l $HADOOP_USER -c /usr/bin/ssh-keygen
  su -l $HADOOP_USER -c "cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys"
fi

# baixar spark se nao existir o arquivo
if [ ! -f $SPARK_BINARY_FILE ]; then
  echo baixando spark
  wget $SPARK_DOWNLOAD_URL
fi

# descompacta spark
if [ ! -d $SPARK_BINARY_DIR ]; then
  echo descompactando spark
  tar zxf $SPARK_BINARY_FILE
  chown -R $HADOOP_USER:$HADOOP_GROUP $SPARK_BINARY_DIR
fi

function pathfix() {
 echo $1 | sed -e 's/\//\\\//g'
}

# inicializar configuracoes
sed -i 's/.*export JAVA_HOME.*/export JAVA_HOME='`pathfix $JAVA_HOME`'/' $HADOOP_HOME/etc/hadoop/hadoop-env.sh
cp templates/hdfs-site.xml.template $HADOOP_HOME/etc/hadoop/hdfs-site.xml
# essas linhas vao alterarar NAMENODE_DIR e DATANODE_DIR que estao no template, para o
# conteudo das variaveis $HDFS_NAMENODE_DIR e $HDFS_DATANODE_DIR
sed -i s/NAMENODE_DIR/`pathfix $HDFS_NAMENODE_DIR`/ $HADOOP_HOME/etc/hadoop/hdfs-site.xml
sed -i s/DATANODE_DIR/`pathfix $HDFS_DATANODE_DIR`/ $HADOOP_HOME/etc/hadoop/hdfs-site.xml

# executar hadoop
DIR_BASE=$PWD

cd $HADOOP_BINARY_DIR

# inicializar hdfs se nao existir
if [ ! -d $HDFS_NAMENODE_DIR ]; then
  mkdir -p $HDFS_NAMENODE_DIR
  chown -R $HADOOP_USER:$HADOOP_USER $HDFS_NAMENODE_DIR
  su -l hadoop -c "$HADOOP_HOME/bin/hadoop namenode -format"
fi
if [ ! -d $HDFS_DATANODE_DIR ]; then
  mkdir -p $HDFS_DATANODE_DIR
  chown -R $HADOOP_USER:$HADOOP_USER $HDFS_DATANODE_DIR
  su -l hadoop -c "$HADOOP_HOME/bin/hadoop datanode -format"
fi

if [ "$1" = "stop" ]; then
#su -l $HADOOP_USER -c "$HADOOP_HOME/sbin/stop-all.sh"
$HADOOP_HOME/sbin/stop-all.sh
else
  #su -l $HADOOP_USER -c "$HADOOP_HOME/sbin/start-all.sh"
  echo inicializar hadoop: $HADOOP_HOME
  cd $HADOOP_HOME
  echo $HADOOP_HOME/sbin/start-all.sh
fi
#$HADOOP_HOME/bin/hdfs --daemon start namenode
#$HADOOP_HOME/bin/hdfs --daemon start datanode
#$HADOOP_HOME/bin/yarn --daemon start resourcemanager
#$HADOOP_HOME/bin/yarn --daemon start nodemanager
#su -l $HADOOP_USER -c "$HADOOP_HOME/bin/yarn --daemon start proxyserver"
#su -l $HADOOP_USER -c "$HADOOP_HOME/bin/mapred --daemon start historyserver"


# reset path
export PATH=$OLDPATH
