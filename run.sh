#!/bin/bash
systemctl start samba
systemctl start pontus-elastic
systemctl start mongod
systemctl start pontus-zookeeper
sleep 10
systemctl start pontus-hbase-master pontus-kafka pontus-hbase-region
sleep 10
systemctl start pontus-graph-nifi
systemctl start pontus-graph-nifi
sleep 50
echo "grant 'af66dfe2-6ee6-4d09-8727-802a56da9fb5', 'RW', 'janusgraph'; exit" | su - pontus -c "env JAVA_HOME=/etc/alternatives/jre /opt/pontus/pontus-hbase/current/bin/hbase shell"

if [[ ! -f /etc/pki/java/shadow.jks ]]; then

  /etc/alternatives/jre/bin/java \
    -cp /opt/pontus/pontus-graph/current/lib/pontus-gdpr-graph-1.2.0.jar \
    -Dshadow.user.keystore.location=/etc/pki/java/shadow.jks \
    -Dshadow.user.keystore.pwd=pa55word \
    -Dshadow.user.key.alias=shadow \
    -Dshadow.user.key.pwd=pa55word \
    -Dshadow.user.key.size=4096 \
    uk.gov.cdp.shadow.user.auth.util.KeyStoreCreator

fi
systemctl start pontus-graph
systemctl start pontus-graph
sleep 10
systemctl start pontus-nifi
sleep 10
systemctl start pontus-keycloak  pontus-nginx
/setup-formio.sh
systemctl start pontus-formio

touch  /run-flag

