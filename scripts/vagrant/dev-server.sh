#!/bin/sh
vagrant ssh -c "sudo mount -o bind /node_modules /vagrant/node_modules"
vagrant ssh -c "cd /vagrant && bin/coco-dev-server"

