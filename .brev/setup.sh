#!/bin/bash

set -eu pipefail

####################################################################################
##### Brev.dev setup script. See docs for more: https://docs.brev.dev          #####
####################################################################################

##### Node v14.x + npm #####
(echo ""; echo "##### Node v14.x + npm #####"; echo "";)
sudo apt install ca-certificates
curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-get install -y nodejs

(echo ""; echo "##### Setup Deps #####"; echo "";)
npm install --also=dev
npm run build 
