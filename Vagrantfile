# -*- mode: ruby -*-
# vi: set ft=ruby :

# Original content copyright (c) 2014 dpen2000 licensed under the MIT license

VAGRANTFILE_API_VERSION = "2"
Vagrant.require_version ">= 1.5.0" , "<= 1.8.6"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Ubuntu 14.04 compatible with both VirtualBox and VMWare Fusion
  # see https://github.com/phusion/open-vagrant-boxes#readme
  config.vm.box = "phusion/ubuntu-14.04-amd64"

  config.vm.hostname = "coco-dev"

  config.vm.network "forwarded_port", guest: 3000, host: 13000
  config.vm.network "forwarded_port", guest: 9485, host: 19485

  config.vm.define "default" do |default|
    default.vm.provision "shell", path: "scripts/vagrant/core/provision.sh", privileged: false
  end
  
  config.vm.define "brunchv2", autostart: false do |brunchv2|
    brunchv2.vm.provision "shell", path: "scripts/vagrant/core/provision.sh", privileged: false
    brunchv2.vm.provision "shell", path: "scripts/vagrant/core/update-brunchv2.sh", privileged: false
  end

  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 2
    #v.gui = true
  end

  config.vm.provider "vmware_fusion" do |v|
    v.vmx["memsize"] = "2048"
    v.vmx["numvcpus"] = 2
  end

end
