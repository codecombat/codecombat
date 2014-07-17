from __future__ import print_function
__author__ = u'schmatz'
from downloader import Downloader
import tarfile
import errors
from errors import DownloadCorruptionError
import warnings
import os
from configuration import Configuration
from dependency import Dependency
import shutil
from which import which
import subprocess
from stat import S_IRWXU,S_IRWXG,S_IRWXO
import sys

if sys.version_info.major >= 3:
    raw_input = input 

class Node(Dependency):
    def __init__(self,configuration):
        super(self.__class__, self).__init__(configuration)
        operating_system = configuration.system.operating_system
        self.config.directory.create_directory_in_tmp(u"node")
        if operating_system == u"mac":
            self.downloader = MacNodeDownloader(self)
        elif operating_system == u"win":
            self.downloader = WindowsNodeDownloader(self)
            self.config.directory.create_directory_in_bin(u"node") #TODO: Fix windows node installation
        elif operating_system == u"linux":
            self.downloader = LinuxNodeDownloader(self)
    @property
    def tmp_directory(self):
        return self.config.directory.tmp_directory
    @property
    def bin_directory(self):
        return self.config.directory.bin_directory

    def download_dependencies(self):
        install_directory = self.config.directory.bin_directory + os.sep + u"node"
        if os.path.exists(install_directory):
            print(u"Skipping Node download because " + install_directory + " exists.")
        else:
            self.downloader.download()
            self.downloader.decompress()
    def bashrc_string(self):
        return "COCO_NODE_PATH=" + self.config.directory.bin_directory + os.sep + u"node" + os.sep + "bin" + os.sep +"node"
    def install_dependencies(self):
        install_directory = self.config.directory.bin_directory + os.sep + u"node"
        #check for node here
        if self.config.system.operating_system in ["mac","linux"] and not which("node"):
            unzipped_node_path = self.findUnzippedNodePath()
            print("Copying node into /usr/local/bin/...")
            shutil.copy(unzipped_node_path + os.sep + "bin" + os.sep + "node","/usr/local/bin/")
            os.chmod("/usr/local/bin/node",S_IRWXG|S_IRWXO|S_IRWXU)
        if os.path.exists(install_directory):
            print(u"Skipping creation of " + install_directory + " because it exists.")
        else:
            unzipped_node_path = self.findUnzippedNodePath()
            shutil.copytree(self.findUnzippedNodePath(),install_directory)
        wants_to_upgrade = True
        if self.check_if_executable_installed(u"npm"):
            warning_string = u"A previous version of npm has been found. \nYou may experience problems if you have a version of npm that's too old.Would you like to upgrade?(y/n) "
            from distutils.util import strtobool
            print(warning_string)
            #for bash script, you have to somehow redirect stdin to raw_input()
            user_input = raw_input()
            while True:
                try:
                    wants_to_upgrade = strtobool(user_input)
                except:
                    print(u"Please enter y or n. ")
                    user_input = raw_input()
                    continue
                break
        if wants_to_upgrade:
            if sys.version_info.major < 3:
                import urllib2, urllib
            else:
                import urllib.request as urllib
            print(u"Retrieving npm update script...")
            npm_install_script_path  = install_directory + os.sep + u"install.sh"
            urllib.urlretrieve(u"https://npmjs.org/install.sh",filename=npm_install_script_path)
            print(u"Retrieved npm install script. Executing...")
            subprocess.call([u"sh", npm_install_script_path])
            print(u"Updated npm version installed")



    def findUnzippedNodePath(self):
        return self.downloader.download_directory + os.sep + \
               (next(os.walk(self.downloader.download_directory))[1])[0]
    def check_if_executable_installed(self,name):
        executable_path = which(name)
        if executable_path:
            return True
        else:
            return False

    def check_node_version(self):
        version = subprocess.check_output(u"node -v")
        return version
    def check_npm_version(self):
        version = subprocess.check_output(u"npm -v")
        return version


class NodeDownloader(Downloader):
    @property
    def download_url(self):
        raise NotImplementedError
    @property
    def download_directory(self):
        return self.dependency.tmp_directory + os.sep + u"node"
    @property
    def downloaded_file_path(self):
        return self.download_directory + os.sep + u"node.tgz"
    def download(self):
        print(u"Downloading Node from URL " + self.download_url)
        self.download_file(self.download_url,self.downloaded_file_path)
        self.check_download()
    def decompress(self):
        print(u"Decompressing Node...")
        tfile = tarfile.open(self.downloaded_file_path)
        #TODO: make directory handler class
        tfile.extractall(self.download_directory)
        print(u"Decompressed Node into " + self.download_directory)

    def check_download(self):
        isFileValid = tarfile.is_tarfile(self.downloaded_file_path)
        if not isFileValid:
            raise DownloadCorruptionError(u"Node download was corrupted.")



class LinuxNodeDownloader(NodeDownloader):
    @property
    def download_url(self):
        if self.dependency.config.mem_width == 64:
            return u"http://nodejs.org/dist/v0.10.24/node-v0.10.24-linux-x64.tar.gz"
        else:
            return u"http://nodejs.org/dist/v0.10.24/node-v0.10.24-linux-x86.tar.gz"

class WindowsNodeDownloader(NodeDownloader):
    @property
    def download_url(self):
        raise NotImplementedError(u"Needs MSI to be executed to install npm")
        #"http://nodejs.org/dist/v0.10.24/x64/node-v0.10.24-x64.msi"
        if self.dependency.config.mem_width == 64:
            return u"http://nodejs.org/dist/v0.10.24/x64/node.exe"
        else:
            return u"http://nodejs.org/dist/v0.10.24/node.exe"

class MacNodeDownloader(NodeDownloader):
    @property
    def download_url(self):
        if self.dependency.config.mem_width == 64:
            return u"http://nodejs.org/dist/v0.10.24/node-v0.10.24-darwin-x64.tar.gz"
        else:
            return u"http://nodejs.org/dist/v0.10.24/node-v0.10.24-darwin-x86.tar.gz"


