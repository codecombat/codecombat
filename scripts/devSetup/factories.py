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
        super(self.__class__, self).setup()
