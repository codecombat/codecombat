#!/bin/bash -e
# Original content copyright (c) 2014 dpen2000 licensed under the MIT license

# some defaults
NODE_VERSION="5.x" # 0.10 | 0.12 | 4.x | 5.x | 6.x
NODE_EXACT_VERSION="5.11.0"

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
curl -sL https://deb.nodesource.com/setup_${NODE_VERSION} | sudo -E bash -
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/mongodb.list

echo "updating apt sources..."
sudo apt-get update

echo "installing prerequisites..."
sudo apt-get -y install --no-install-recommends build-essential git g++ make curl wget python2.7 dos2unix

# install nvm
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.0/install.sh | bash
source ~/.nvm/nvm.sh

# install node.js
echo "installing node.js..."
nvm install ${NODE_EXACT_VERSION}
n=$(which node);n=${n%/bin/node}; chmod -R 755 $n/bin/*; sudo cp -r $n/{bin,lib,share} /usr/local

# sudo apt-get -y install nodejs
echo "upgrading npm..."
sudo npm install -g npm@latest # upgrade npm
sudo npm install -g geoip-lite
sudo npm install -g bower

# bind /vagrant/node_modules so that it does not leak through to the host file system
# which triggers symlink and path size issues on Windows hosts
mkdir -p /vagrant/node_modules
sudo mkdir -p /node_modules
sudo chown -R vagrant:vagrant /node_modules
sudo mount --bind /node_modules /vagrant/node_modules

# prepare
find /vagrant/app -type f -exec dos2unix {} \;
find /vagrant/vendor -type f -exec dos2unix {} \;
sudo chown -R vagrant:vagrant /home/vagrant

# install npm modules
echo "installing modules..."
cd /vagrant
npm install
bower install

# install mongo
echo "installing mongodb..."
sudo apt-get -y install --no-install-recommends mongodb-org


# start mongodb
sudo service mongod start

# populate mongo
echo "populating mongodb..."
exec /vagrant/scripts/vagrant/fillMongo.sh
