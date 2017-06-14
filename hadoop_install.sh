#!/bin/bash

#
# Copyright 2017 Pablo Rebollo and Omar Soto
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

function pcline {

    TEXT=$1
    printf "%b" "\e[1;34m-------------------- $TEXT --------------------\n\e[0m"

}

function clean_installation {

        pcline clean_installation

        yum -y install psmisc
        killall java
        killall java
        rm -rf /opt/hadoop
        rm -rf /opt/spark
        rm -rf /opt/apache-hive

}

function update_os {

    pcline update_os
    yum -y update --exclude=*kernel*

}

# Source: https://gist.github.com/n0ts/40dd9bd45578556f93e7
function get_java_latest {

  pcline get_java_latest

  ext=rpm
  jdk_version=$JDKVER

  if [ -n "$1" ]; then
      if [ "$1" == "tar" ]; then
          exit="tar.gz"
      fi
  fi

  readonly url="http://www.oracle.com"
  readonly jdk_download_url1="$url/technetwork/java/javase/downloads/index.html"
  readonly jdk_download_url2=$(curl -s $jdk_download_url1 | egrep -o "\/technetwork\/java/\javase\/downloads\/jdk${jdk_version}-downloads-.+?\.html" | head -1 | cut -d '"' -f 1)
  [[ -z "$jdk_download_url2" ]] && error "Could not get jdk download url - $jdk_download_url1"

  readonly jdk_download_url3="${url}${jdk_download_url2}"
  readonly jdk_download_url4=$(curl -s $jdk_download_url3 | egrep -o "http\:\/\/download.oracle\.com\/otn-pub\/java\/jdk\/[7-8]u[0-9]+\-(.*)+\/jdk-[7-8]u[0-9]+(.*)linux-x64.$ext" | tail -1)

  JAVAURL=$jdk_download_url4

}

function set_java {

    pcline set_java
    wget --quiet --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" $JAVAURL -O $INSTALLERSDIR/jdk-linux-x64.rpm

    cd $INSTALLERSDIR

    rpm -Uvh $INSTALLERSDIR/jdk-linux-x64.rpm

    cd

}

function set_hadoop {

    pcline set_hadoop

    yum -y install rsync
    wget -P $INSTALLERSDIR --quiet -c $HADOOPURL
    tar xzf $INSTALLERSDIR/hadoop-$HADOOPVER.tar.gz -C $INSTALLERSDIR
    rsync -a $INSTALLERSDIR/hadoop-$HADOOPVER/ /opt/hadoop/
    chown -R $CUSER:root /opt/hadoop/

cat > /home/$CUSER/.bash_profile << EOF
# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

# User specific environment and startup programs

PATH=\$PATH:\$HOME/bin

export PATH

# JAVA env variables
export JAVA_HOME=/usr/java/default
export PATH=\$PATH:\$JAVA_HOME/bin
export CLASSPATH=.:\$JAVA_HOME/jre/lib:\$JAVA_HOME/lib:\$JAVA_HOME/lib/tools.jar

# HADOOP env variables
export HADOOP_HOME=/opt/hadoop
export HADOOP_COMMON_HOME=\$HADOOP_HOME
export HADOOP_HDFS_HOME=\$HADOOP_HOME
export HADOOP_MAPRED_HOME=\$HADOOP_HOME
export HADOOP_YARN_HOME=\$HADOOP_HOME
export HADOOP_OPTS="-Djava.library.path=\$HADOOP_HOME/lib/native"
export HADOOP_COMMON_LIB_NATIVE_DIR=\$HADOOP_HOME/lib/native

#export SCALA_HOME=/opt/scala
#export PATH=\$PATH:\$SCALA_HOME/bin
#export CLASSPATH=\$CLASSPATH:\$SCALA_HOME/lib

export HIVE_HOME=/opt/apache-hive

export HADOOP_CONF_DIR=\$HADOOP_HOME/etc/hadoop
export YARN_CONF_DIR=\$HADOOP_CONF_DIR
export SPARK_HOME=/opt/spark

export PATH=\$PATH:\$HADOOP_HOME/sbin:\$HADOOP_HOME/bin:\$HIVE_HOME/bin:\$SPARK_HOME/bin

export PYTHONPATH=\$SPARK_HOME/python/lib/py4j-0.10.4-src.zip:\$PYTHONPATH
export PYSPARK_PYTHON=/usr/local/bin/python3.5
export PYSPARK_DRIVER_PYTHON=/usr/local/bin/python3.5

alias pip='/usr/local/bin/pip3.5'
alias python='/usr/local/bin/python3.5'
EOF

cat > $INSTALLERSDIR/hdfs-site.xml.patch << EOF
--- hdfs-site.xml
+++ hdfs-site.xml
@@ -18,4 +18,18 @@

 <configuration>

+  <property>
+    <name>dfs.namenode.name.dir</name>
+    <value>/export/hadoop/dfs/name</value>
+    <description></description>
+  </property>
+  <property>
+    <name>dfs.datanode.data.dir</name>
+    <value>/export/hadoop/dfs/data</value>
+    <description></description>
+  </property>
+  <property>
+    <name>dfs.namenode.datanode.registration.ip-hostname-check</name>
+    <value>false</value>
+  </property>
 </configuration>
EOF

yum -y install patch

patch /opt/hadoop/etc/hadoop/hdfs-site.xml $INSTALLERSDIR/hdfs-site.xml.patch

cat > $INSTALLERSDIR/core-site.xml.patch << EOF
--- core-site.xml
+++ core-site.xml
@@ -17,4 +17,8 @@
 <!-- Put site-specific property overrides in this file. -->

 <configuration>
+   <property>
+      <name>fs.default.name</name>
+      <value>hdfs://master:9000/</value>
+   </property>
 </configuration>
EOF

patch /opt/hadoop/etc/hadoop/core-site.xml $INSTALLERSDIR/core-site.xml.patch

cat > /opt/hadoop/bin/mapred-site.xml << EOF
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->

<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
</configuration>
EOF

cat > $INSTALLERSDIR/yarn-site.xml.patch << EOF
--- yarn-site.xml
+++ yarn-site.xml
@@ -15,5 +15,22 @@
 <configuration>

 <!-- Site specific YARN configuration properties -->
+    <property>
+        <name>yarn.resourcemanager.hostname</name>
+        <value>master</value>
+        <description>The hostname of the RM.</description>
+    </property>
+    <property>
+        <name>yarn.nodemanager.aux-services</name>
+        <value>mapreduce_shuffle</value>
+    </property>
+    <property>
+        <name>yarn.nodemanager.pmem-check-enabled</name>
+        <value>false</value>
+    </property>
+    <property>
+        <name>yarn.nodemanager.vmem-check-enabled</name>
+        <value>false</value>
+    </property>

 </configuration>
EOF

  patch /opt/hadoop/etc/hadoop/yarn-site.xml $INSTALLERSDIR/yarn-site.xml.patch

  mkdir -p /export/hadoop/dfs/name
  mkdir -p /export/hadoop/dfs/data

  chown -R $CUSER:root /export

}

function set_scala {

  pcline set_scala

  wget -P $INSTALLERSDIR --quiet -c $SCALAURL
  tar xzf $INSTALLERSDIR/scala-$SCALAVER.tgz -C $INSTALLERSDIR
  rsync -a $INSTALLERSDIR/scala-$SCALAVER/ /opt/scala/
  chown -R $CUSER:root /opt/scala/

}

function set_hosts {

  pcline set_hosts

  cd

  i=0

  for host in $(cat $NODESFILE) ; do
    if [ "$i" -eq "0" ]; then
      word="master"
    else
      printf -v ii "%02d" $i
      word="data$ii"
    fi

    if ! grep -q "$host" /etc/hosts; then
      echo "$host $word" >> /etc/hosts;
    fi

    i=$((i+1))
  done;

}

function set_python3 {

  pcline set_python3

  yum -y install gcc ncurses-devel readline-devel openssl-devel tk-devel

  wget -P $INSTALLERSDIR --quiet -c $PYTHONURL
  tar xzf $INSTALLERSDIR/Python-$PYTHONVER.tgz -C $INSTALLERSDIR

cat > $INSTALLERSDIR/Python-$PYTHONVER/Modules/Setup/Setup.patch << EOF
--- Setup
+++ Setup
@@ -358,7 +358,7 @@
 # Andrew Kuchling's zlib module.
 # This require zlib 1.1.3 (or later).
 # See http://www.gzip.org/zlib/
-#zlib zlibmodule.c -I\$(prefix)/include -L\$(exec_prefix)/lib -lz
+zlib zlibmodule.c -I\$(prefix)/include -L\$(exec_prefix)/lib -lz

 # Interface to the Expat XML parser
 #
EOF

  patch $INSTALLERSDIR/Python-$PYTHONVER/Modules/Setup $INSTALLERSDIR/Python-$PYTHONVER/Modules/Setup/Setup.patch

  cd $INSTALLERSDIR/Python-$PYTHONVER/Modules/zlib

  ./configure >> python3-make 2>&1
  make >> python3-make 2>&1
  make install >> python3-make 2>&1

  cd $INSTALLERSDIR/Python-$PYTHONVER

  ./configure >> python3-make 2>&1
  make altinstall >> python3-make 2>&1

  python3.5 -m ensurepip
  pip3.5 install numpy

  cd

}

function set_spark {

  pcline set_spark
  wget -P $INSTALLERSDIR --quiet -c $SPARKURL
  tar xzf $INSTALLERSDIR/spark-$SPARKVER-bin-hadoop$SHADOOPVER.tgz -C $INSTALLERSDIR
  rsync -a $INSTALLERSDIR/spark-$SPARKVER-bin-hadoop$SHADOOPVER/ /opt/spark/
  chown -R $CUSER:root /opt/spark/

}

function set_hive {

  pcline set_hive

  sudo yum -y install mysql-server mysql-connector-java
  service mysqld start
  /usr/bin/mysqladmin -u root password 'Clust3R'

  mysql -u root -pClust3R -e "CREATE USER 'hiveuser'@'%' IDENTIFIED BY 'hivepassword';"
  mysql -u root -pClust3R -e "GRANT all on *.* to 'hiveuser'@localhost identified by 'hivepassword';"
  mysql -u root -pClust3R -e "FLUSH PRIVILEGES;"

  ln -s /usr/share/java/mysql-connector-java.jar $HIVE_HOME/lib/mysql-connector-java.jar

  wget -P $INSTALLERSDIR --quiet -c $HIVEURL
  tar xzf $INSTALLERSDIR/apache-hive-$HIVEVER-bin.tar.gz -C $INSTALLERSDIR
  rsync -a $INSTALLERSDIR/apache-hive-$HIVEVER-bin/ /opt/apache-hive/
  chown -R $CUSER:root /opt/apache-hive/

  $HIVE_HOME/bin/schematool -initSchema -dbType mysql
  
}

if [[ ! `whoami` = "root" ]]; then
    echo "You must have administrative privileges to run this script."
    echo "Try 'sudo ./hadoop_install.sh'"
    exit 1
fi

PWD=$(pwd)
INSTALLERSDIR=$PWD/INSTALLERSDIR
[[ -d $INSTALLERSDIR ]] || mkdir $INSTALLERSDIR
NODESFILE=$PWD/nodes

JDKVER="8"

HADOOPVER="2.7.3"
HADOOPURL="http://www-us.apache.org/dist/hadoop/common/hadoop-$HADOOPVER/hadoop-$HADOOPVER.tar.gz"

SCALAVER="2.12.2"
SCALAURL="http://downloads.typesafe.com/scala/$SCALAVER/scala-$SCALAVER.tgz"

PYTHONVER="3.5.2"
PYTHONURL="https://www.python.org/ftp/python/$PYTHONVER/Python-$PYTHONVER.tgz"

SPARKVER="2.1.1"
SHADOOPVER="2.7"
SPARKURL="http://apache.claz.org/spark/spark-$SPARKVER/spark-$SPARKVER-bin-hadoop$SHADOOPVER.tgz"

HIVEVER="2.1.1"
HIVEURL="http://apache.claz.org/hive/hive-$HIVEVER/apache-hive-$HIVEVER-bin.tar.gz"

JAVA_HOME=/usr/java/default

PATH=$JAVA_HOME/bin:$PATH

export JAVA_HOME PATH

CUSER=omar.soto2

clean_installation
update_os
get_java_latest
set_java
set_hadoop
#set_scala
set_hosts
set_python3
set_spark
set_hive
