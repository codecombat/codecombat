from __future__ import print_function
__author__ = u'schmatz'
import configuration
import errors
import subprocess
import os
from which import which
#git clone https://github.com/nwinter/codecombat.git coco
class RepositoryInstaller():
    def __init__(self,config):
        self.config = config
        assert isinstance(self.config,configuration.Configuration)
        if not self.checkIfGitExecutableExists():
            if self.config.system.operating_system == "linux":
                raise errors.CoCoError("Git is missing. Please install it (try 'sudo apt-get install git')\nIf you are not using Ubuntu then please see your Linux Distribution's documentation for help installing git.")
            elif self.config.system.operating_system == "mac":
                raise errors.CoCoError("Git is missing. Please install the Xcode command line tools.")
            raise errors.CoCoError(u"Git is missing. Please install git.")
            #http://stackoverflow.com/questions/9329243/xcode-4-4-and-later-install-command-line-tools
        if not self.checkIfCurlExecutableExists():
            if self.config.system.operating_system == "linux":
                raise errors.CoCoError("Curl is missing. Please install it(try 'sudo apt-get install curl')\nIf you are not using Ubuntu then please see your Linux Distribution's documentation for help installing curl.")
            elif self.config.system.operating_system == "mac":
                raise errors.CoCoError("Curl is missing. Please install the Xcode command line tools.")
            raise errors.CoCoError(u"Git is missing. Please install git.")
    def checkIfGitExecutableExists(self):
        gitPath = which(u"git")
        if gitPath:
            return True
        else:
            return False
    #TODO: Refactor this into a more appropriate file
    def checkIfCurlExecutableExists(self):
        curlPath = which("curl")
        if curlPath:
            return True
        else:
            return False
    def cloneRepository(self):
        print(u"Cloning repository...")
        #TODO: CHANGE THIS BEFORE LAUNCH
        return_code = True
        git_folder = self.config.directory.root_install_directory + os.sep + "coco"
        print("Installing into " + git_folder)
        return_code = subprocess.call("git clone " + self.config.repository_url +" coco",cwd=self.config.directory.root_install_directory,shell=True)
        #TODO: remove this on windos
        subprocess.call("chown -R " +git_folder + " 0777",shell=True)
        if return_code and self.config.system.operating_system != u"windows":
            #raise errors.CoCoError("Failed to clone git repository")
            import shutil
            #import sys
            #sys.stdout.flush()
            raw_input(u"Copy it now")
            #shutil.copytree(u"/Users/schmatz/coco",self.config.directory.root_install_directory + os.sep + u"coco")
            print(u"Copied tree just for you")
            #print("FAILED TO CLONE GIT REPOSITORY")
            #input("Clone the repository and click any button to continue")
        elif self.config.system.operating_system == u"windows":
            raise errors.CoCoError(u"Windows doesn't support automated installations of npm at this point.")
        else:
            print(u"Cloned git repository")
    def install_node_packages(self):
        print(u"Installing node packages...")
        #TODO: "Replace npm with more robust package
        #npm_location = self.config.directory.bin_directory + os.sep + "node" + os.sep + "bin" + os.sep + "npm"
        npm_location = u"npm"
        return_code = subprocess.call([npm_location,u"install"],cwd=self.config.directory.root_dir + os.sep + u"coco")
        if return_code:
            raise errors.CoCoError(u"Failed to install node packages")
        else:
            print(u"Installed node packages!")
