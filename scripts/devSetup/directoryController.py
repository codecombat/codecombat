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
        #return self.root_dir + os.sep + u"codecombat"
        return self.root_dir + os.sep + "coco" + os.sep + "bin"
    @property
    def tmp_directory(self):
        return self.root_install_directory + os.sep + u"tmp"
    @property
    def bin_directory(self):
        return self.root_install_directory

    def create_directory_in_tmp(self,subdirectory):
        os.mkdir(self.generate_path_for_directory_in_tmp(subdirectory))

    def generate_path_for_directory_in_tmp(self,subdirectory):
        return self.tmp_directory + os.sep + subdirectory
    def create_directory_in_bin(self,subdirectory):
        full_path = self.bin_directory + os.sep + subdirectory
        os.mkdir(full_path)

    def create_base_directories(self):
        #first create the directory for the development environment to be installed in
        try:
            #os.mkdir(self.root_install_directory)
            #then the tmp directory for file downloads and the like
            os.mkdir(self.tmp_directory)
            #then the bin directory for binaries(also includes binaries for dependencies?
            #os.mkdir(self.bin_directory)
        except:
            #cleanup whatever we created
            #self.remove_directories()
            raise errors.CoCoError(u"There was an error creating the directory structure, do you have correct permissions? Please remove all and start over.")


    def remove_directories(self):
        print u"Removed directories created!"
        shutil.rmtree(self.tmp_directory)
        #shutil.rmtree(self.root_install_directory)
