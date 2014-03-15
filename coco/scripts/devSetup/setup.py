#setup.py
#A setup script for the CodeCombat development environment

# The MIT License (MIT)
#
# Copyright (c) 2013 CodeCombat Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

import factories
import os
import errors
import ctypes
def check_if_root():
    is_admin = False
    try:
        uid = os.getuid()
        if uid == 0:
            is_admin = True
    except:
        is_admin = True
        #is_admin = ctypes.windll.shell32.IsUserAnAdmin()
    if not is_admin:
        raise errors.CoCoError(u"You need to be root. Run as sudo.")

if __name__ == u"__main__":
    print("Code Combat Development Environment Setup Script")
    check_if_root()
    setup = factories.constructSetup()
    setup.setup()


