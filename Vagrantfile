# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"

  config.vm.network "forwarded_port", guest: 3000, host: 9998
  config.vm.network "forwarded_port", guest: 35432, host: 35432
  config.vm.network "forwarded_port", guest: 29992, host: 9992

  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
    # vb.gui = true

    # Customize the amount of memory on the VM:
    vb.memory = "4096"
    vb.cpus = 3
  end

  config.vm.provider "vmware_fusion" do |v|
    v.vmx["memsize"] = "4096"
    v.vmx["numvcpus"] = 2
  end

  config.vm.provision "shell", path: "./development/vagrant/provision.sh", privileged: false
  config.vm.provision "shell", path: "./development/vagrant/mount.sh", privileged: true, run: 'always'
end
