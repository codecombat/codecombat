#!/bin/bash -e
RUBY_VERSION=2.6.1
NODE_VERSION=6.16.0

COCO_CLIENT_ROOT=/coco/client

CLIENT_NODE_MODULES=/vagrant/mounts/node_modules/client

# inform apt that there's no user to answer interactive questions
export DEBIAN_FRONTEND=noninteractive
BASHRC=$HOME/.bashrc

echo "Installing system dependencies..."
sudo apt-get update
sudo apt-get install -y git curl libssl-dev libreadline-dev zlib1g-dev autoconf bison \
                        build-essential libyaml-dev libncurses5-dev \
                        libffi-dev libgdbm-dev python2.7 python-pip build-essential

echo "Installing Ruby..."

export PATH=$PATH:$HOME/.rbenv/bin:$HOME/.rbenv/shims
curl -sL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-installer | bash -

if ! rbenv versions | grep -q $RUBY_VERSION; then
    rbenv install $RUBY_VERSION
    rbenv global $RUBY_VERSION

    echo 'export PATH=$PATH:$HOME/.rbenv/bin:$HOME/.rbenv/shims' >> $BASHRC
    echo 'eval "$(rbenv init -)"' >> $BASHRC
fi

echo "Installing nvm..."
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash

if ! grep -q nvm $BASHRC; then
    echo 'NVM_DIR="$HOME/.nvm"' >> $BASHRC
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' >> $BASHRC
fi

NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"

echo "Installing node $NODE_VERSION..."
nvm install $NODE_VERSION
nvm alias default $NODE_VERSION

echo "Installing Node / Ruby global dependencies"
gem install compass
npm install -g node-gyp read

echo "Configuring node_modules directories..."

# bind /vagrant/node_modules so that it does not leak through to the host file system
# which triggers symlink and path size issues on Windows hosts
if [[ ! -d $CLIENT_NODE_MODULES ]]; then
    sudo mkdir -p $CLIENT_NODE_MODULES
    sudo mkdir -p $COCO_CLIENT_ROOT/node_modules
    sudo chown -R vagrant:vagrant $CLIENT_NODE_MODULES
    sudo chown -R vagrant:vagrant $COCO_CLIENT_ROOT
fi

# Make sure to remount
sudo bash /vagrant/mounts/coco_server/development/vagrant/mount.sh

echo "Installing client dependencies..."
pushd $COCO_CLIENT_ROOT
npm install --ignore-scripts
npm rebuild node-sass
npm install read
npm run bower -- install
npm run build-aether
npm run webpack
popd

if ! grep -q DEV_CONTAINER $BASHRC; then
    echo 'export DEV_CONTAINER=1' >> $BASHRC
fi
