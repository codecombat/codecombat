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
def constructSetup():
    config = configuration.Configuration()
    if config.system.operating_system == u"mac":
        print("Mac detected, architecture: " + str(config.system.get_virtual_memory_address_width()) + " bit")
        return MacSetup(config)
    elif config.system.operating_system == u"win":
        print("Windows detected, architecture: " + str(config.system.get_virtual_memory_address_width())+ " bit")
        raise NotImplementedError("Windows is not supported at this time.")
        #return WinSetup(config)
    elif config.system.operating_system == u"linux":
        print("Linux detected, architecture: " + str(config.system.get_virtual_memory_address_width())+ " bit")
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
        except:
            print("Mongod not found.")
        if "v2.5.4" not in mongo_version_string:
            print("MongoDB 2.5.4 not found, so installing...")
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
        print("Copying bin scripts...")

        script_location =self.config.directory.root_dir + os.sep + "coco" + os.sep + "scripts" + os.sep + "devSetup" + os.sep + "bin"
        #print("Script location: " + script_location)
        #print("Destination: "+ self.config.directory.root_install_directory)
        #for filename in glob.glob(os.path.join(script_location, '*.*')):
        #    shutil.copy(filename, self.config.directory.root_install_directory)
        print("Removing temporary directories")
        self.config.directory.remove_directories()
        print("Changing permissions of files...")
        #TODO: Make this more robust and portable(doesn't pose security risk though)
        subprocess.call("chmod -R 755 " + self.config.directory.root_dir + os.sep + "coco" + os.sep + "bin",shell=True)

        print("Done! If you want to start the server, head into /coco/bin and run ")
        print("1. ./coco-mongodb")
        print("2. ./coco-brunch")
        print("3. ./coco-dev-server")
        print("Once brunch is done, visit http://localhost:3000!")
        #print self.mongo.bashrc_string()
        #print self.node.bashrc_string()
        #print "COCO_DIR="+ self.config.directory.root_dir + os.sep + "coco"
    def cleanup(self):
        self.config.directory.remove_directories()


class MacSetup(SetupFactory):
    def setup(self):
        super(self.__class__, self).setup()
class WinSetup(SetupFactory):
    def setup(self):
        super(self.__class__, self).setup()
class LinuxSetup(SetupFactory):
    def setup(self):
        super(self.__class__, self).setup()
