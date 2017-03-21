#!/bin/bash
# Original content copyright (c) 2014 dpen2000 licensed under the MIT license
mkdir -p /vagrant/temp
cd /vagrant/temp
rm -f dump.tar.gz
rm -rf dump
echo "Downloading mongo dump file..."
wget --no-verbose http://analytics.codecombat.com:8080/dump.tar.gz
tar xzf dump.tar.gz --no-same-owner
echo "Restoring mongo dump file..."
mongorestore --quiet --drop
if [ -d /vagrant/temp/backup ]
then
  echo "Restoring mongo backup..."
  cd /vagrant/temp/backup
  mongorestore --quiet
fi
