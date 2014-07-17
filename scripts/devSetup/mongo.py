from __future__ import print_function
__author__ = u'schmatz'
from downloader import Downloader
import tarfile
from errors import DownloadCorruptionError
import warnings
import os
from configuration import Configuration
from dependency import Dependency
import sys
import shutil

class MongoDB(Dependency):
    def __init__(self,configuration):
        super(self.__class__, self).__init__(configuration)
        operating_system = configuration.system.operating_system
        self.config.directory.create_directory_in_tmp(u"mongo")

        if operating_system == u"mac":
            self.downloader = MacMongoDBDownloader(self)
        elif operating_system == u"win":
            self.downloader = WindowsMongoDBDownloader(self)
        elif operating_system == u"linux":
            self.downloader = LinuxMongoDBDownloader(self)
    @property
    def tmp_directory(self):
        return self.config.directory.tmp_directory
    @property
    def bin_directory(self):
        return self.config.directory.bin_directory

    def bashrc_string(self):
        return "COCO_MONGOD_PATH=" + self.config.directory.bin_directory + os.sep + u"mongo" + os.sep +"bin" + os.sep + "mongod"


    def download_dependencies(self):
        install_directory = self.config.directory.bin_directory + os.sep + u"mongo"
        if os.path.exists(install_directory):
            print(u"Skipping MongoDB download because " + install_directory + " exists.")
        else:
            self.downloader.download()
            self.downloader.decompress()
    def install_dependencies(self):
        install_directory = self.config.directory.bin_directory + os.sep + u"mongo"
        if os.path.exists(install_directory):
            print(u"Skipping creation of " + install_directory + " because it exists.")
        else:
            shutil.copytree(self.findUnzippedMongoBinPath(),install_directory)

    def findUnzippedMongoBinPath(self):
        return self.downloader.download_directory + os.sep + \
               (next(os.walk(self.downloader.download_directory))[1])[0] + os.sep + u"bin"




class MongoDBDownloader(Downloader):
    @property
    def download_url(self):
        raise NotImplementedError
    @property
    def download_directory(self):
        return self.dependency.tmp_directory + os.sep + u"mongo"
    @property
    def downloaded_file_path(self):
        return self.download_directory + os.sep + u"mongodb.tgz"
    def download(self):
        print(u"Downloading MongoDB from URL " + self.download_url)
        self.download_file(self.download_url,self.downloaded_file_path)
        self.check_download()
    def decompress(self):
        print(u"Decompressing MongoDB...")
        tfile = tarfile.open(self.downloaded_file_path)
        #TODO: make directory handler class
        tfile.extractall(self.download_directory)
        print(u"Decompressed MongoDB into " + self.download_directory)

    def check_download(self):
        isFileValid = tarfile.is_tarfile(self.downloaded_file_path)
        if not isFileValid:
            raise DownloadCorruptionError(u"MongoDB download was corrupted.")



class LinuxMongoDBDownloader(MongoDBDownloader):
    @property
    def download_url(self):
        if self.dependency.config.mem_width == 64:
            return u"http://fastdl.mongodb.org/linux/mongodb-linux-x86_64-latest.tgz"
        else:
            warnings.warn(u"MongoDB *really* doesn't run well on 32 bit systems. You have been warned.")
            return u"http://fastdl.mongodb.org/linux/mongodb-linux-i686-latest.tgz"

class WindowsMongoDBDownloader(MongoDBDownloader):
    @property
    def download_url(self):
        #TODO: Implement Windows Vista detection
        warnings.warn(u"If you have a version of Windows older than 7, MongoDB may not function properly!")
        if self.dependency.config.mem_width == 64:
            return u"http://fastdl.mongodb.org/win32/mongodb-win32-x86_64-2008plus-latest.zip"
        else:
            return u"http://fastdl.mongodb.org/win32/mongodb-win32-i386-latest.zip"

class MacMongoDBDownloader(MongoDBDownloader):
    @property
    def download_url(self):
        return u"http://fastdl.mongodb.org/osx/mongodb-osx-x86_64-latest.tgz"


