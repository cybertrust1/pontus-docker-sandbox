#!/bin/bash 

DIR="$( cd "$(dirname "$0")" ; pwd -P )"
echo DIR is $DIR

CURDIR=`pwd`
cd $DIR/..

cd pontus-dist/opt
rm -f *.tar
tar --exclude='pontus/pontus-nifi/nifi-1.6.0/work' --exclude='pontus/pontus-nifi/nifi-1.6.0/state'  --exclude='pontus/pontus-nifi/nifi-1.6.0/*repository'   -cvpf ./pontus.tar pontus
$DIR/split-tar -s 50M ./pontus.tar 

cd $CURDIR

