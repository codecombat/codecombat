# -*- mode: ruby -*-
# vi: set ft=ruby :

# Original content copyright (c) 2014 dpen2000 licensed under the MIT license

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  
  config.vm.box = "ubuntu/trusty64"
  
  config.vm.network "forwarded_port", guest: 3000, host: 3000
  config.vm.network "forwarded_port", guest: 9485, host: 9485

  config.vm.provision "shell", path: "scripts/vagrant/provision.sh"
  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 2
  end

end
