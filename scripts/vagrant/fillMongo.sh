#!/bin/bash
# Original content copyright (c) 2014 dpen2000 licensed under the MIT license
mkdir -p /vagrant/temp
cd /vagrant/temp
rm -f dump.tar.gz
rm -rf dump
wget http://analytics.codecombat.com:8080/dump.tar.gz
tar xzvf dump.tar.gz --no-same-owner
mongorestore --drop
if [ -d /vagrant/temp/backup ]
then
  cd /vagrant/temp/backup
  mongorestore
fi
