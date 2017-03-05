## About hadoop_install.sh

This script is designed to install a Hadoop DFS, YARN and MapReduce **CentOS** cluster with 5 nodes (one of them master). This script was done by Pablo Rebollo (from the University of Puerto Rico) and was modified by me to add extra configuration required to use YARN and MapReduce.

## Installation

To be able to use this script, the first thing that must be done is cloning this repository.

```
git clone https://github.com/omarpr/hadoop_install
```

Then, modify the following lines of the file **hadoop_install.sh**. In them, you will specify the name of the user account (this is important for permissions) and the IP of the master node and each data node.

```shell
CUSER=omar.soto2
MASTER=136.140.210.1
NODE01=136.140.210.2
NODE02=136.140.210.3
NODE03=136.140.210.4
NODE04=136.140.210.5
```

Copy the script to all the servers that you will have in the cluster. To install it, just run the script:

```shell
./hadoop_install.sh
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
