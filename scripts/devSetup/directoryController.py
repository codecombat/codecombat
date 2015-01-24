__author__ = u'schmatz'
import configuration
import os
import sys
import errors
import shutil
class DirectoryController(object):
    def __init__(self,config):
        assert isinstance(config,configuration.Configuration)
        self.config = config
        self.root_dir = self.config.system.get_current_working_directory()

    @property
    def root_install_directory(self):
        return self.root_dir + os.sep + "coco" + os.sep + "bin"
    @property
    def tmp_directory(self):
        return self.root_install_directory + os.sep + u"tmp"
    @property
    def bin_directory(self):
        return self.root_install_directory

    def mkdir(self, path):
        if os.path.exists(path):
            print(u"Skipping creation of " + path + " because it exists.")
        else:
            os.mkdir(path)
        
    def create_directory_in_tmp(self,subdirectory):
        path = self.generate_path_for_directory_in_tmp(subdirectory)
        self.mkdir(path)

    def generate_path_for_directory_in_tmp(self,subdirectory):
        return self.tmp_directory + os.sep + subdirectory
    def create_directory_in_bin(self,subdirectory):
        full_path = self.bin_directory + os.sep + subdirectory
        self.mkdir(full_path)

    def create_base_directories(self):
        shutil.rmtree(self.root_dir + os.sep + "coco" + os.sep + "node_modules",ignore_errors=True) #just in case
        try:
            if os.path.exists(self.tmp_directory):
                self.remove_tmp_directory()
            os.mkdir(self.tmp_directory)
        except:
            raise errors.CoCoError(u"There was an error creating the directory structure, do you have correct permissions? Please remove all and start over.")

    def remove_directories(self):
        shutil.rmtree(self.bin_directory + os.sep + "node",ignore_errors=True)
        shutil.rmtree(self.bin_directory + os.sep + "mongo",ignore_errors=True)
    def remove_tmp_directory(self):
        shutil.rmtree(self.tmp_directory)



