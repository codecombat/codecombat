@ECHO off
powershell .\get_var.ps1 config.coco %1 > var.tmp
set /p %1= < var.tmp
del /q var.tmp