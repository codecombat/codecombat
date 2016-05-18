#!/bin/bash
mkdir -p /vagrant/temp
cd /vagrant/temp
rm -fr backup
mkdir backup
cd backup
mongodump -db coco --collection users 
mongodump -db coco --collection earnedachievements
