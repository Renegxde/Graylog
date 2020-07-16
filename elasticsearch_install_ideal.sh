#!/bin/bash

#**BEFORE RUNNING THIS ENSURE THE DISK ARE MOUNTED ON THE PROPER DIRECTORIES (/data/elasticsearch and /var/log/elasticsearch)**



#Variables go here:
#IP_ADDRESS=`ifconfig | grep inet | grep broad | awk '{print $2}'`

#Enter the IP Address of the elasticsearch server here
IP_ADDRESS="10.2.31.22"

HTTP_BIND_ADDRESS=`echo "$IP_ADDRESS:9000"`
ELASTICSEARCH_DATA_DIR="/data/elasticsearch"

#Change the heap size to half the total amount of physical memory on the machine
ELASTICSEARCH_HEAP_SIZE="8g"

#ELASTICSEARCH_NODE_1="172.31.23.152"
#ELASTICSEARCH_NODE_2="172.31.25.51"
#ELASTICSEARCH_NODE_3="172.31.21.32"

yum update -y
yum install wget -y
yum install unix2dos -y
yum install policycoreutils-python -y
yum install java-1.8.0-openjdk-headless.x86_64 -y
yum install pwgen -y

### SELinux prep
# Elasticsearch
semanage port -a -t http_port_t -p tcp 9200
semanage port -a -t http_port_t -p tcp 9300

###### Setup Elasticsearch install
# Get and install elasticsearch

rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
printf '[elasticsearch-6.x]
name=Elasticsearch repository for 6.x packages
baseurl=https://artifacts.elastic.co/packages/oss-6.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md ' > /etc/yum.repos.d/elasticsearch.repo

yum install -y elasticsearch-oss

# Archive the shipped config


mv /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml.orig

# Create a simple Elasticsearch config
printf "cluster.name: graylog
action.auto_create_index: false
path.data: $ELASTICSEARCH_DATA_DIR
path.logs: /var/log/elasticsearch
" > /etc/elasticsearch/elasticsearch.yml

printf "network.host: $IP_ADDRESS" >> /etc/elasticsearch/elasticsearch.yml

# Fix the JVM options
cp /etc/elasticsearch/jvm.options /etc/elasticsearch/jvm.options.orig
sed -i "s/-Xms1g/-Xms$ELASTICSEARCH_HEAP_SIZE/g" /etc/elasticsearch/jvm.options
sed -i "s/-Xmx1g/-Xmx$ELASTICSEARCH_HEAP_SIZE/g" /etc/elasticsearch/jvm.options

# Ensure permissions are correct

chown elasticsearch:elasticsearch -R /etc/elasticsearch/*
#chown elasticsearch:elasticsearch -R /var/lib/elasticsearch/*
chown elasticsearch:elasticsearch -R /data/*

# Enable Elasticsearch at boot
systemctl enable elasticsearch

# Optionally start Elasticsearch

# systemctl start elasticsearch


