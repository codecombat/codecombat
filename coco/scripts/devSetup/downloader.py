from __future__ import print_function
__author__ = 'schmatz'
from configuration import Configuration
import sys
if sys.version_info.major < 3:
    import urllib
else:
    import urllib.request as urllib
from dependency import Dependency
class Downloader:
    def __init__(self,dependency):
        assert isinstance(dependency, Dependency)
        self.dependency = dependency
    @property
    def download_directory(self):
        raise NotImplementedError
    def download(self):
        raise NotImplementedError
    def download_file(self,url,filePath):
        urllib.urlretrieve(url,filePath,self.__progress_bar_reporthook)
    def decompress(self):
        raise NotImplementedError
    def check_download(self):
        raise NotImplementedError

    def __progress_bar_reporthook(self,blocknum,blocksize,totalsize):
        #http://stackoverflow.com/a/13895723/1928667
        #http://stackoverflow.com/a/3173331/1928667
        bars_to_display = 70
        amount_of_data_downloaded_so_far = blocknum * blocksize
        if totalsize > 0:
            progress_fraction = float(amount_of_data_downloaded_so_far) / float(totalsize)
            progress_percentage = progress_fraction * 1e2
            stringToDisplay = '\r[{0}] {1:.1f}%'.format('#'*int(bars_to_display*progress_fraction),progress_percentage)
            print(stringToDisplay,end=' ')
            if amount_of_data_downloaded_so_far >= totalsize:
                print("\n",end=' ')
        else:
            stringToDisplay = '\r File size unknown. Read {0} bytes.'.format(amount_of_data_downloaded_so_far)
            print(stringToDisplay,end=' ')

