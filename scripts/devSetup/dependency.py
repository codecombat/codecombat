__author__ = u'schmatz'

from configuration import Configuration

class Dependency(object):
    def __init__(self,configuration):
        assert isinstance(configuration,Configuration)
        self.config = configuration
    def download_dependencies(self):
        raise NotImplementedError
    def install_dependencies(self):
        raise NotImplementedError

