#!/bin/bash -x

DIR="$( cd "$(dirname "$0")" ; pwd -P )"
echo DIR=$DIR


if [[ "$1" == "--rebuild" ]] ; then 
CWD=`pwd`
cd $DIR

cd ..
for i in */build-local.sh; do 
  if [[ $i != *"docker"* ]]; then 
    echo i=$i
    LDIR="$( cd "$(dirname "$i")" ; pwd -P )"
    echo LDIR=$LDIR
    cd $LDIR
    ./build-local.sh
    cd -
  fi 
  
done

cd $CWD

fi

createDF () {

counter=$1
> df.${counter}
cat >> "df.${counter}" << EOF
FROM local/pvgdpr2-$(( counter - 1))
ENV container docker
EOF

}

createFinalDF () {

counter=$1
(( counter --))
> df.final
cat >> df.final << EOF
FROM local/pvgdpr2-${counter}
MAINTAINER Leo Martins lmartins@pontusnetworks.com
ARG home=/root
ENV container docker
ENV TERM=xterm-color
EXPOSE 8443 5005-5010
VOLUME [ "/sys/fs/cgroup" ]
CMD ["/usr/sbin/init"]
EOF

}

rebase () {
 
  ./build-tar.sh
  docker images |egrep 'local|<none>'  | awk '{ print $3 }'|xargs docker rmi

  CONTAINER_ID=temp
  cp Dockerfile.0 df.0
  counter=1
  for i in ../pontus-dist/opt/pontus-*.tar; do
    echo $counter $i
    createDF $counter
    (( counter ++))
  done

  counter=1
  for i in ../pontus-dist/opt/pontus-*.tar; do
    docker build --rm  --no-cache -t local/pvgdpr2-$((counter - 1)):latest -f df.$((counter - 1)) ./dummy
    docker create --name $CONTAINER_ID -t local/pvgdpr2-$(( counter - 1))
    cat $i | docker cp - $CONTAINER_ID:/opt/
    docker start $CONTAINER_ID
    docker exec -it $CONTAINER_ID chown -R pontus:pontus /opt
    docker commit $CONTAINER_ID local/pvgdpr2-$(( counter -1 )):latest
    docker rm -f $CONTAINER_ID
    (( counter ++))
  done
  
  (( counter -- ))

  createFinalDF $counter

}

if [[ "$*" =~ "rebase" ]] ; then 
 rebase
fi 


CONTAINER_ID=open-source-gdpr2
docker build --rm  --no-cache -t pontusvision/open-source-gdpr2 -f df.final ./dummy
#docker create --name $CONTAINER_ID -t pontusvision/open-source-gdpr2

#docker create --privileged --name  $CONTAINER_ID -v /sys/fs/cgroup:/sys/fs/cgroup:ro -p5006:5006 -p5007:5007 --dns 127.0.0.1 --dns-search pontusvision.com -p5005:5005 -p8443:8443 --hostname=pontus-sandbox.pontusvision.com -t pontusvision/open-source-gdpr2
docker create --privileged --name  $CONTAINER_ID -v /sys/fs/cgroup:/sys/fs/cgroup:ro -p5006:5006 -p5007:5007 --dns-search pontusvision.com -p5005:5005 -p8443:8443 --hostname=pontus-sandbox.pontusvision.com -t pontusvision/open-source-gdpr2

docker start $CONTAINER_ID

ansible-playbook -e 'tls_home=/tmp/foo' -i 127.0.0.1 playbook.yml

docker cp /tmp/foo/java $CONTAINER_ID:/etc/pki
docker cp /tmp/foo/private $CONTAINER_ID:/etc/pki

for i in dummy/*service ; do 
  docker cp $i $CONTAINER_ID:/etc/systemd/system
done

docker exec -i $CONTAINER_ID yum install -y openssl
docker exec -i $CONTAINER_ID cp /etc/pki/java/localhost.pem /etc/pki/java/localhost-nginx.pem
docker exec -i $CONTAINER_ID chmod 600 /etc/pki/java/localhost.pem 
#docker exec -i $CONTAINER_ID openssl x509 -outform der -in /etc/pki/java/root-ca.crt -out /etc/pki/java/root-ca.der
#docker exec -i $CONTAINER_ID openssl x509 -outform der -in /etc/pki/java/root-ca.crt -out /etc/pki/java/root-ca.der
docker exec -i $CONTAINER_ID keytool -delete -alias pontus-ca  -keystore /etc/pki/java/cacerts -storepass changeit
docker exec -i $CONTAINER_ID keytool -import -alias pontus-ca -trustcacerts -file /etc/pki/java/root-ca.crt -keystore /etc/pki/java/cacerts -storepass changeit -noprompt
docker exec -i $CONTAINER_ID mkdir /opt/pontus/pontus-nginx/current/logs/
docker exec -i $CONTAINER_ID cp /etc/pki/java/localhost.jks /etc/pki/java/keystore.jks
docker exec -i $CONTAINER_ID chown -R pontus:pontus /opt/pontus
docker exec -i $CONTAINER_ID -u pontus /opt/pontus/pontus-keycloak/current/bin/add-user-keycloak.sh -u admin -p admin
docker exec -i $CONTAINER_ID yum install -y gnutls krb5-workstation
docker exec -i $CONTAINER_ID ln -s /opt/pontus/pontus-samba/4.8.1 /opt/pontus/pontus-samba/current
docker exec -i $CONTAINER_ID mkdir -p /opt/pontus/pontus-samba/4.8.1/var/locks
docker exec -i $CONTAINER_ID mkdir -p /opt/pontus/pontus-samba/4.8.1/var/run
docker cp  ../pontus-dist/opt/pontus/pontus-samba/current/config-samba.sh $CONTAINER_ID:/opt/pontus/pontus-samba/current/config-samba.sh
docker exec -i $CONTAINER_ID chmod 755 /opt/pontus/pontus-samba/current/config-samba.sh 
docker exec -i $CONTAINER_ID /opt/pontus/pontus-samba/current/config-samba.sh
docker exec -i $CONTAINER_ID chown -R root: /opt/pontus/pontus-samba
docker exec -i $CONTAINER_ID rm -f /etc/systemd/system/pontus-hbase.service /etc/systemd/system/pontus-hbase-regionserver.service
docker exec -i $CONTAINER_ID ln -s /opt/pontus/pontus-samba/current/etc /etc/samba
docker exec -i $CONTAINER_ID ln -s /opt/pontus/pontus-nginx/current/conf /etc/nginx
for i in pontus-formio.tar.gz.*; do 
  docker cp $i $CONTAINER_ID:/opt/pontus/
done
docker cp mongodb.tar.gz $CONTAINER_ID:/
docker cp -a ./setup-formio.sh $CONTAINER_ID:/setup-formio.sh


docker cp -a ./stop.sh $CONTAINER_ID:/stop.sh
docker cp -a ./run.sh $CONTAINER_ID:/run.sh
#docker cp pontus-formio.service $CONTAINER_ID:/etc/systemd/system/
docker cp pontus-all.service $CONTAINER_ID:/etc/systemd/system/
docker exec -i $CONTAINER_ID systemctl enable  pontus-all pontus-zookeeper pontus-nifi pontus-nginx  pontus-keycloak pontus-kafka   pontus-hbase-region pontus-hbase-master  pontus-graph pontus-graph-nifi pontus-elastic samba mongod 
docker exec -i $CONTAINER_ID  systemctl daemon-reload 
docker commit $CONTAINER_ID pontusvision/open-source-gdpr2:latest
docker exec -i $CONTAINER_ID  yum -y install nodejs
docker commit $CONTAINER_ID pontusvision/open-source-gdpr2:latest
docker exec -i $CONTAINER_ID  yum -y install npm
docker commit $CONTAINER_ID pontusvision/open-source-gdpr2:latest

docker tag pontusvision/open-source-gdpr2:latest pontusvisiongdpr/open-source-gdpr2.1:latest

#docker exec -i $CONTAINER_ID  systemctl start samba 
#docker exec -i $CONTAINER_ID  systemctl start pontus-elastic 
#docker exec -i $CONTAINER_ID  systemctl start mongod 
#docker exec -i $CONTAINER_ID  systemctl start pontus-zookeeper 
#docker exec -i $CONTAINER_ID  systemctl start pontus-hbase-master pontus-kafka pontus-hbase-region 
#docker exec -i $CONTAINER_ID  systemctl start pontus-graph-nifi 
#docker exec -i $CONTAINER_ID  systemctl start pontus-graph 
#docker exec -i $CONTAINER_ID  systemctl start pontus-nifi 
#docker exec -i $CONTAINER_ID  systemctl start pontus-keycloak pontus-gui pontus-nginx


