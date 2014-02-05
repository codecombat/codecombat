@echo off
setlocal EnableDelayedExpansion

set "git-path=C:\Program Files (x86)\Git"

set "PATH=%PATH%;%git-path%\bin;%git-path%\cmd" /M

git clone https://github.com/codecombat/codecombat.git C:\Coco\

pause

endlocal