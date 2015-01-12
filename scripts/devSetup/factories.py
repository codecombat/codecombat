__author__ = u'schmatz'

import errors
import configuration
import mongo
import node
import repositoryInstaller
import ruby
import shutil
import os
import glob
import subprocess
def print_computer_information(os_name,address_width):
  print(os_name + " detected, architecture: " + str(address_width) + " bit")
def constructSetup():
    config = configuration.Configuration()
    address_width = config.system.get_virtual_memory_address_width()
    if config.system.operating_system == u"mac":
        print_computer_information("Mac",address_width)
        return MacSetup(config)
    elif config.system.operating_system == u"win":
        print_computer_information("Windows",address_width)
        raise NotImplementedError("Windows is not supported at this time.")
    elif config.system.operating_system == u"linux":
        print_computer_information("Linux",address_width)
        return LinuxSetup(config)

class SetupFactory(object):
    def __init__(self,config):
        self.config = config
        self.mongo = mongo.MongoDB(self.config)
        self.node = node.Node(self.config)
        self.repoCloner = repositoryInstaller.RepositoryInstaller(self.config)
        self.ruby = ruby.Ruby(self.config)
    def setup(self):
        mongo_version_string = ""
        try:
            mongo_version_string = subprocess.check_output("mongod --version",shell=True)
            mongo_version_string = mongo_version_string.decode(encoding='UTF-8')
        except Exception as e:
            print("Mongod not found: %s"%e)
        if "v2.6." not in mongo_version_string:
            if mongo_version_string:
                print("Had MongoDB version: %s"%mongo_version_string)
            print("MongoDB not found, so installing a local copy...")
            self.mongo.download_dependencies()
            self.mongo.install_dependencies()
        self.node.download_dependencies()
        self.node.install_dependencies()
        #self.repoCloner.cloneRepository()
        self.repoCloner.install_node_packages()
        self.ruby.install_gems()

        print ("Doing initial bower install...")
        bower_path = self.config.directory.root_dir + os.sep + "coco" + os.sep + "node_modules" + os.sep + ".bin" + os.sep + "bower"
        subprocess.call(bower_path + " --allow-root install",shell=True,cwd=self.config.directory.root_dir + os.sep + "coco")
        print("Removing temporary directories")
        self.config.directory.remove_tmp_directory()
        print("Changing permissions of files...")
        #TODO: Make this more robust and portable(doesn't pose security risk though)
        subprocess.call("chmod -R 755 " + self.config.directory.root_dir + os.sep + "coco" + os.sep + "bin",shell=True)
        chown_command = "chown -R " + os.getenv("SUDO_USER") + " bower_components"
        chown_directory = self.config.directory.root_dir + os.sep + "coco"
        subprocess.call(chown_command,shell=True,cwd=chown_directory)

        print("")
        print("Done! If you want to start the server, head into coco/bin and run ")
        print("1. ./coco-mongodb")
        print("2. ./coco-brunch ")
        print("3. ./coco-dev-server")
        print("NOTE: brunch may need to be run as sudo if it doesn't work (ulimit needs to be set higher than default)")
        print("")
        print("Before can play any levels you must update the database. See the Setup section here:")
        print("https://github.com/codecombat/codecombat/wiki/Developer-environment#setup")
        print("")
        print("Go to http://localhost:3000 to see your local CodeCombat in action!")
    def cleanup(self):
        self.config.directory.remove_tmp_directory()

class MacSetup(SetupFactory):
    def setup(self):
        super(self.__class__, self).setup()

class WinSetup(SetupFactory):
    def setup(self):
        super(self.__class__, self).setup()

class LinuxSetup(SetupFactory):
    def setup(self):
        self.distroSetup()
        super(self.__class__, self).setup()

    def detectDistro(self):
        distro_checks = {
            "arch": "/etc/arch-release",
            "ubuntu": "/etc/lsb-release"
            }
        for distro, path in distro_checks.items():
            if os.path.exists(path):
                return(distro)

    def distroSetup(self):
        distro = self.detectDistro()
        if distro == "arch":
            print("Arch Linux detected. Would you like to install \n"
                  "NodeJS and MongoDB via pacman? [y/N]")
            if raw_input().lower() in ["y", "yes"]:
                try:
                    subprocess.check_call(["pacman", "-S",
                                           "nodejs", "mongodb",
                                           "--noconfirm"])
                except subprocess.CalledProcessError as err:
                    print("Installation failed. Retry, Continue, or "
                          "Abort? [r/c/A]")
                    answer = raw_input().lower()
                    if answer in ["r", "retry"]:
                        return(self.distroSetup())
                    elif answer in ["c", "continue"]:
                        return()
                    else:
                        exit(1)
                else:
                    try:
                        print("Enabling and starting MongoDB in systemd.")
                        subprocess.check_call(["systemctl", "enable",
                                               "mongodb.service"])
                        subprocess.check_call(["systemctl", "start",
                                               "mongodb.service"])
                        print("Node and Mongo installed. Continuing.")
                    except subprocess.CalledProcessError as err:
                        print("Mongo failed to start. Aborting")
                        exit(1)
        if distro == "ubuntu":
            print("Ubuntu installation detected. Would you like to install \n"
                  "NodeJS and MongoDB via apt-get? [y/N]")
            if raw_input().lower() in ["y", "yes"]:
                print("Adding repositories for MongoDB and NodeJS...")
                try:
                    subprocess.check_call(["apt-key", "adv",
                                           "--keyserver",
                                           "hkp://keyserver.ubuntu.com:80",
                                           "--recv", "7F0CEB10"])
                    subprocess.check_call(["add-apt-repository",
                                           "deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen"])
                    subprocess.check_call(["curl", "-sL",
                                           "https://deb.nodesource.com/setup",
                                           "|", "bash"], shell=True)
                    subprocess.check_call(["apt-get", "update"])
                except subprocess.CalledProcessError as err:
                    print("Adding repositories failed. Retry, Install without"
                          "adding \nrepositories, Skip apt-get installation, "
                          "or Abort? [r/i/s/A]")
                    answer = raw_input().lower()
                    if answer in ["r", "retry"]:
                        return(self.distroSetup())
                    elif answer in ["i", "install"]:
                        pass
                    elif answer in ["s", "skip"]:
                        return()
                    else:
                        exit(1)
                else:
                    try:
                        print("Repositories added successfully. Installing NodeJS and MongoDB.")
                        subprocess.check_call(["apt-get", "install",
                                               "nodejs", "mongodb-org", "-y"])
                    except subprocess.CalledProcessError as err:
                        print("Installation via apt-get failed. \nContinue "
                              "with manual installation, or Abort? [c/A]")
                        if raw_input().lower() in ["c", "continue"]:
                            return()
                        else:
                            exit(1)
                    else:
                        print("NodeJS and MongoDB installed successfully. "
                              "Staring MongoDB.")
                        try:
                            subprocess.check_call(["service", "mongod", "start"])
                        except subprocess.CalledProcessError as err:
                            print("Mongo failed to start. Aborting.")
                            exit(1)
