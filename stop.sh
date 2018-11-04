#!/bin/bash
#if [[ ! -f /run-flag ]]; then 

systemctl stop pontus-nifi

systemctl stop pontus-keycloak pontus-gui pontus-nginx

sleep 10
systemctl stop pontus-graph-nifi
sleep 10
systemctl stop pontus-graph
sleep 30

systemctl stop pontus-hbase-master pontus-kafka pontus-hbase-region
systemctl stop pontus-elastic
sleep 10
systemctl stop pontus-zookeeper
sleep 10
systemctl stop samba

systemctl stop mongod
rm  /run-flag
