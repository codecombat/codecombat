__author__ = u'schmatz'
from systemConfiguration import SystemConfiguration
import os
import directoryController
import errors
class Configuration(object):
    def __init__(self):
        self.system = SystemConfiguration()
        assert isinstance(self.system,SystemConfiguration)
        self.directory = directoryController.DirectoryController(self)
        self.directory.create_base_directories()
        #self.repository_url = u"https://github.com/nwinter/codecombat.git"
        self.repository_url = "https://github.com/schmatz/cocopractice.git"
    @property
    def mem_width(self):
        return self.system.virtual_memory_address_width



