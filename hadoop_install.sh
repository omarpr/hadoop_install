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

}

function update_os {

    pcline update_os
    yum -y update --exclude=*kernel*

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

## JAVA env variables
export JAVA_HOME=/usr/java/default
export PATH=\$PATH:\$JAVA_HOME/bin
export CLASSPATH=.:\$JAVA_HOME/jre/lib:\$JAVA_HOME/lib:\$JAVA_HOME/lib/tools.jar
## HADOOP env variables
export HADOOP_HOME=/opt/hadoop
export HADOOP_COMMON_HOME=\$HADOOP_HOME
export HADOOP_HDFS_HOME=\$HADOOP_HOME
export HADOOP_MAPRED_HOME=\$HADOOP_HOME
export HADOOP_YARN_HOME=\$HADOOP_HOME
export HADOOP_OPTS="-Djava.library.path=\$HADOOP_HOME/lib/native"
export HADOOP_COMMON_LIB_NATIVE_DIR=\$HADOOP_HOME/lib/native
export PATH=\$PATH:\$HADOOP_HOME/sbin:\$HADOOP_HOME/bin
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
+<property>
+   <name>fs.default.name</name>
+   <value>hdfs://master:9000/</value>
+</property>
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
@@ -15,5 +15,14 @@
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

 </configuration>
EOF

patch /opt/hadoop/etc/hadoop/yarn-site.xml $INSTALLERSDIR/yarn-site.xml.patch

cat > $INSTALLERSDIR/hosts.patch << EOF
--- hosts
+++ hosts
@@ -1,2 +1,7 @@
 127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
 ::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
+$MASTER master
+$NODE01 data01
+$NODE02 data02
+$NODE03 data03
+$NODE04 data04
EOF

patch /etc/hosts $INSTALLERSDIR/hosts.patch

    mkdir -p /export/hadoop/dfs/name
    mkdir -p /export/hadoop/dfs/data

    chown -R $CUSER:root /export

    #su - hadoop
}

INSTALLERSDIR=$PWD/INSTALLERSDIR
[[ -d $INSTALLERSDIR ]] || mkdir $INSTALLERSDIR

JDKVER="1.8.0_121"
JAVAVER="8u121"
JAVAURL="http://download.oracle.com/otn-pub/java/jdk/$JAVAVER-b13/jdk-$JAVAVER-linux-x64.rpm"
JAVAURL="http://download.oracle.com/otn-pub/java/jdk/8u121-b13/e9e7ea248e2c4826b92b3f075a80e441/jdk-8u121-linux-x64.rpm"

HADOOPVER="2.7.3"
HADOOPURL="http://www-us.apache.org/dist/hadoop/common/hadoop-$HADOOPVER/hadoop-$HADOOPVER.tar.gz"

JAVA_HOME=/usr/java/jdk$JDKVER

PATH=$JAVA_HOME/bin:$PATH

export JAVA_HOME PATH

CUSER=omar.soto2
MASTER=136.140.210.1
NODE01=136.140.210.2
NODE02=136.140.210.3
NODE03=136.140.210.4
NODE04=136.140.210.5

clean_installation
update_os
set_java
set_hadoop
