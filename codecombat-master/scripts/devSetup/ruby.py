from __future__ import print_function
__author__ = u'root'

import dependency
import configuration
import shutil
import errors
import subprocess
from which import which
class Ruby(dependency.Dependency):
    def __init__(self,config):
        self.config = config
        assert isinstance(config,configuration.Configuration)
        is_ruby_installed = self.check_if_ruby_exists()
        is_gem_installed = self.check_if_gem_exists()
        if is_ruby_installed and not is_gem_installed:
            #this means their ruby is so old that RubyGems isn't packaged with it
            raise errors.CoCoError(u"You have an extremely old version of Ruby. Please upgrade it to get RubyGems.")
        elif not is_ruby_installed:
            self.install_ruby()
        elif is_ruby_installed and is_gem_installed:
            print(u"Ruby found.")
    def check_if_ruby_exists(self):
        ruby_path = which(u"ruby")
        return bool(ruby_path)
    def check_if_gem_exists(self):
        gem_path = which(u"gem")
        return bool(gem_path)
    def install_ruby(self):
        operating_system = self.config.system.operating_system
        #Ruby is on every recent Mac, most Linux distros
        if operating_system == u"windows":
            self.install_ruby_on_windows()
        elif operating_system == u"mac":
            raise errors.CoCoError(u"Ruby should be installed with Mac OSX machines. Please install Ruby.")
        elif operating_system == u"linux":
            raise errors.CoCoError(u"Please install Ruby (try 'sudo apt-get install ruby').\nIf you are not using Ubuntu then please see your Linux Distribution's documentation for help installing ruby.")
    def install_ruby_on_windows(self):
        raise NotImplementedError

    def install_gems(self):
        gem_install_status = subprocess.call([u"gem",u"install",u"--no-user-install",u"sass"])
