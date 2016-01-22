#!/bin/bash -e
# Original content copyright (c) 2014 dpen2000 licensed under the MIT license

# some defaults
DISTRO="trusty"
NODE_VERSION="0.10" # 0.10 | 0.12 | 4.x | 5.x

# inform apt that there's no user to answer interactive questions
export DEBIAN_FRONTEND=noninteractive

# Set default ulimits
cat <<- EOF > /tmp/limits.conf
* soft nofile 10000
* hard nofile 10000
EOF
sudo mv /tmp/limits.conf /etc/security/limits.conf
sudo chown root:root /etc/security/limits.conf

# install prerequisites
curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | sudo apt-key add -
echo "deb https://deb.nodesource.com/node_${NODE_VERSION} ${DISTRO} main
deb-src https://deb.nodesource.com/node_${NODE_VERSION} ${DISTRO} main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/mongodb.list

echo "updating apt sources..."
sudo apt-get -qq update

echo "installing prerequisites..."
sudo apt-get -qqy install --no-install-recommends git g++ make curl wget

# install node.js
echo "installing node.js..."
sudo apt-get -qqy install nodejs
echo "upgrading npm..."
sudo npm install -g npm@latest # upgrade npm
sudo npm install -g geoip-lite
sudo npm install -g bower

# bind /vagrant/node_modules so that it does not leak through to the host file system
# which triggers symlink and path size issues on Windows hosts
mkdir -p /vagrant/node_modules
sudo mkdir -p /node_modules
sudo chown vagrant:vagrant /node_modules
sudo mount --bind /node_modules /vagrant/node_modules
cd /vagrant

# install npm modules
echo "installing modules..."
npm install
bower install

# install mongo
echo "installing mongodb..."
sudo apt-get -qqy install --no-install-recommends mongodb-org

# populate mongo
echo "populating mongodb..."
exec /vagrant/scripts/vagrant/fillMongo.sh
