#!/bin/bash
 
#**BEFORE RUNNING THIS MAKE SURE THE DISKS ARE MOUNTED ON THE PROPER DIRECTORIES (/opt/data/graylog and /var/log/graylog-server)**

 
#Variables go here:
#IP_ADDRESS=`ifconfig | grep inet | grep broad | awk '{print $2}'`

#Enter IP Address of the Graylog Server here
IP_ADDRESS="10.2.31.21"


HTTP_BIND_ADDRESS=`echo "$IP_ADDRESS:9000"`
# The below needs to be provided if the client will be connecting over a NAT. This is the external IP address.
# HTTP_PUBLISH_URI_IPNAME="54.224.40.207"
GRAYLOG_JOURNAL_DIR="/opt/data/graylog"

#Enter the IP Address of the Elasticsearch Server here
ELASTICSEARCH_NODE_PORT_0="10.2.31.22:9200"
#ELASTICSEARCH_NODE_PORT_1="172.31.1.2:9200"
#ELASTICSEARCH_NODE_PORT_2="172.31.1.3:9200"
 

yum update -y
yum install wget -y
yum install unix2dos -y
yum install policycoreutils-python -y
yum install java-1.8.0-openjdk-headless.x86_64 -y
yum install epel-release -y
yum install pwgen -y

### SELinux prep
# Graylog
semanage port -a -t http_port_t -p tcp 9000
# Elasticsearch
semanage port -a -t http_port_t -p tcp 9200
# MongoDB
semanage port -a -t mongod_port_t -p tcp 27017

###### Setup mongodb install
# Get and install mongodb

printf '[mongodb-org-4.0]\nname=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/4.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.0.asc' > /etc/yum.repos.d/mongodb-org-4.0.repo

yum install -y mongodb-org

# Add mongodb to start-up
systemctl daemon-reload
systemctl enable mongodb

# Optionally start MongoDB. Graylog will not start if mongodb is not found
systemctl start mongodb

##### Setup Graylog Install
# Get and install Graylog
rpm -Uvh https://packages.graylog2.org/repo/packages/graylog-3.1-repository_latest.rpm
yum install graylog-server -y 
yum install graylog-enterprise-plugins -y
yum install graylog-integrations-plugins -y
yum install graylog-enterprise-integrations-plugins -y

# Archive the original Graylog server.conf
mv /etc/graylog/server/server.conf /etc/graylog/server/server.conf.orig

# Create a new config file
printf "allow_highlighting = false
allow_leading_wildcard_searches = false
content_packs_auto_load = grok-patterns.json
content_packs_dir = /usr/share/graylog-server/contentpacks
#elasticsearch_hosts = http://$ELASTICSEARCH_NODE_PORT_0, http://$ELASTICSEARCH_NODE_PORT_1, http://$ELASTICSEARCH_NODE_PORT_2
elasticsearch_hosts = http://$ELASTICSEARCH_NODE_PORT_0
elasticsearch_analyzer = standard
elasticsearch_index_prefix = graylog
elasticsearch_max_docs_per_index = 20000000
elasticsearch_max_number_of_indices = 20
elasticsearch_replicas = 0
elasticsearch_shards = 4
inputbuffer_processors = 2
inputbuffer_ring_size = 65536
inputbuffer_wait_strategy = blocking
is_master = true
lb_recognition_period_seconds = 3
message_journal_enabled = true
mongodb_max_connections = 1000
mongodb_threads_allowed_to_block_multiplier = 5
node_id_file = /etc/graylog/server/node-id
output_batch_size = 500
outputbuffer_processors = 3
output_fault_count_threshold = 5
output_fault_penalty_seconds = 30
output_flush_interval = 1
plugin_dir = /usr/share/graylog-server/plugin
processbuffer_processors = 5
processor_wait_strategy = blocking
proxied_requests_thread_pool_size = 32
retention_strategy = delete
ring_size = 65536
rotation_strategy = count " > /etc/graylog/server/server.conf

# Comment out this line if you plan to run mongoDB on the localhost (127.0.0.1)
#printf "\nmongodb_uri = mongodb://$HTTP_BIND_ADDRESS/graylog" >> /etc/graylog/server/server.conf


printf "\nmessage_journal_dir = $GRAYLOG_JOURNAL_DIR" >> /etc/graylog/server/server.conf
chown -R graylog:graylog $GRAYLOG_JOURNAL_DIR
chown -R graylog:graylog /var/log/graylog-server
printf "\nhttp_bind_address = $HTTP_BIND_ADDRESS" >> /etc/graylog/server/server.conf
# printf "\nhttp_publish_uri = http://$HTTP_BIND_ADDRESS/" >> /etc/graylog/server/server.conf

# Add a password secret/salt to the Graylog server.conf
# This is included in the script to ensure that the salt is not shared.
# THIS IS FOR STANDALONE SYSTEMS ONLY.
printf "\npassword_secret = `pwgen -N 1 -s 96`" >> /etc/graylog/server/server.conf

# Add the root PW SHA2 hash to the configuration
# Do not calculate this on the box, this example is "yourpassword" 
# An Easy way to generate the hash is below 
# echo -n "Enter Password: " && head -1 </dev/stdin | tr -d '\n' | sha256sum | cut -d" " -f1
# MAKE SURE THAT THIS IS NOT "yourpassword"
#THIS IS FOR STANDALONE SYSTEMS ONLY.
printf "\n root_password_sha2 = e3c652f0ba0b4801205814f8b6bc49672c4c74e25b497770bb89b22cdeb4e951" >> /etc/graylog/server/server.conf

# Enable Graylog server to start at boot
systemctl enable graylog-server

# Optionally start Graylog
# systemctl start graylog-server
 
