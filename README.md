## About hadoop_install.sh

This script is designed to install a **CentOS 6** (and other yum-based OS) cluster with Hadoop DFS, YARN, MapReduce, Apache Hive and Spark of N nodes (one of them master). The original script was done by Pablo Rebollo (from the University of Puerto Rico) and was further improved by me.

## Installation

To use this script, the first step is to clone this repository.

```
git clone https://github.com/omarpr/hadoop_install
```

Then, modify the following lines of the file **hadoop_install.sh**. In them, you will specify the name of the user account (this is important for permissions) and the IP of the master node and each data node.

```shell
CUSER=omar.soto2
```

Modify the **nodes** file to add the IPs of all the nodes of the cluster. The first line of the file will correspond to the **master** node. The other lines will be identified as **dataXX** node.

```
136.145.216.XXX
136.145.216.XXX
136.145.216.XXX
136.145.216.XXX
...
```

Copy the script to all the servers that you will have in the cluster. To install it, just run the script:

```shell
sudo ./hadoop_install.sh
```

Load the **.bash_profile** to have the environment variables ready:

```shell
. ~/.bash_profile
```

To start the NameNode and the YARN (only on **master node**), use this:

```shell
hadoop-daemon.sh start namenode
yarn-daemon.sh start resourcemanager
```

(Remember to format the **HDFS**)

```shell
hdfs namenode -format cluster
```

Run the hadoop_install.sh on each data node (and load .bash_profile) and start the DataNode and NodeManager, using this:

```shell
hadoop-daemon.sh start datanode
yarn-daemon.sh start nodemanager
```

## Useful URLs

HDFS Web Application

```
http://[Master IP]:50070
```

YARN Web Application

```
http://[Master IP]:8088
```

## Useful commands

List directory contents

```shell
hdfs dfs -ls /
```

Make directory recursively

```shell
hdfs dfs -mkdir -p /a/path
```

Balance HDFS with threshold 1%

```shell
export HADOOP_CLIENT_OPTS="-Xmx2048m $HADOOP_CLIENT_OPTS"
hdfs balancer -threshold 1
```

Run PySpark console

```shell
pyspark --master yarn --deploy-mode client --conf='spark.executorEnv.PYTHONHASHSEED=223'
```

Submit PySpark application

```shell
spark-submit [code.py]
```

## PySpark Streaming Template
```python
from pyspark import SparkContext
from pyspark.streaming import StreamingContext

sc = SparkContext(appName="[Application Name]")
sc.setLogLevel("WARN")

ssc = StreamingContext(sc, 60)

# Code to execute every 60 seconds.

ssc.start()
ssc.awaitTermination()
```