__author__ = u'schmatz'
#TODO: Clean these up
class CoCoError(Exception):
    def __init__(self,details):
        self.details = details
    def __str__(self):
        return repr(self.details + u"\n Please contact CodeCombat support, and include this error in your message.")

class NotSupportedError(CoCoError):
    def __init__(self,details):
        self.details = details
    def __str__(self):
        return repr(self.details + u"\n Please contact CodeCombat support, and include this error in your message.")

class DownloadCorruptionError(CoCoError):
    def __init__(self,details):
        self.details = details
    def __str__(self):
        return repr(self.details + u"\n Please contact CodeCombat support, and include this error in your message.")
