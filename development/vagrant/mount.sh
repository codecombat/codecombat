#!/bin/bash -e

mount --bind /vagrant/mounts/coco_client /coco/client
mkdir -p /coco/client/node_modules
mount --bind /vagrant/mounts/node_modules/client /coco/client/node_modules
