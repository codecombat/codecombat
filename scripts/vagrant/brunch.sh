#!/bin/sh
vagrant ssh -c "sudo mount -o bind /node_modules /vagrant/node_modules"
vagrant ssh -c "cd /vagrant && BRUNCH_ENV=vagrant bin/coco-brunch"

