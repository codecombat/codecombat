:: IMPORTANT!!! install curl (if you haven't already) from http://www.confusedbycode.com/curl/#downloads
:: Process List:
  :: 1) Download Files
    :: a) Node-JS
    :: b) Ruby
    :: c) OS-specific installers
      :: I) MongoDB
  :: 2) 

@echo off
setlocal

:: Global Variables
set "temp-dir=C:\Coco-Temp"
set install-log=%temp-dir%\coco-dev-install-log.txt

:: Create The Temporary Directory
IF EXIST %temp-dir% rmdir %temp-dir% /s /q
mkdir %temp-dir%

:: Create Log File
copy /y nul %install-log% > nul



IF EXIST "%PROGRAMFILES(X86)%" (GOTO 64BIT) ELSE (GOTO 32BIT)

:64BIT
  echo Setting up the environment for a 64-bit computer... >> %install-log%
  
  echo downloading: node-js... >> %install-log%
  curl http://nodejs.org/dist/v0.10.24/x64/node-v0.10.24-x64.msi -o %temp-dir%\node-js-setup.exe
  
  echo downloading: ruby... >> %install-log%
  curl http://dl.bintray.com/oneclick/rubyinstaller/rubyinstaller-2.0.0-p353-x64.exe?direct -o %temp-dir%\ruby-setup.exe
  
  :: Some installations require specific windows versions
  for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
  if "%version%" == "5.2" GOTO ver_XP_64
  if "%version%" == "6.0" GOTO ver_Vista_64
  if "%version%" == "6.1" GOTO ver_Win7_8_64
  if "%version%" == "6.2" GOTO ver_Win7_8_64
  if "%version%" == "6.3" GOTO ver_Win7_8_64
  
  GOTO warn_and_exit
GOTO END

:32BIT
  echo Setting up the environment for a 32-bit computer... >> %install-log%
  
  echo downloading: node-js... >> %install-log%
  curl http://nodejs.org/dist/v0.10.24/node-v0.10.24-x86.msi -o %temp-dir%\node-js-setup.exe
  
  echo downloading: ruby... >> %install-log%
  curl http://dl.bintray.com/oneclick/rubyinstaller/rubyinstaller-2.0.0-p353.exe?direct -o %temp-dir%\ruby-setup.exe
  
  :: Some installations require specific windows versions
  for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
  if "%version%" == "5.1" GOTO ver_XP_32
  if "%version%" == "6.0" GOTO ver_Vista_32
  if "%version%" == "6.1" GOTO ver_Win7_8_32
  if "%version%" == "6.2" GOTO ver_Win7_8_32
  if "%version%" == "6.3" GOTO ver_Win7_8_32
  
  GOTO warn_and_exit
GOTO END

:ver_Win7_8_32
  echo downloading: mongo-db... >> %install-log%
  curl http://fastdl.mongodb.org/win32/mongodb-win32-i386-2.5.4.zip -o %temp-dir%\mongodb-setup.zip
goto instal_dev_environment

:ver_Vista_32
  echo downloading: mongo-db... >> %install-log%
  curl http://fastdl.mongodb.org/win32/mongodb-win32-i386-2.5.4.zip -o %temp-dir%\mongodb-setup.zip
goto instal_dev_environment

:ver_XP_32
  echo Sadly we can't support Windows XP... Please upgrade your OS! >> %install-log%
goto END

:ver_Win7_8_64
  echo downloading: mongo-db... >> %install-log%
  curl http://fastdl.mongodb.org/win32/mongodb-win32-x86_64-2008plus-2.5.4.zip -o %temp-dir%\mongodb-setup.zip
goto instal_dev_environment

:ver_Vista_64
  echo downloading: mongo-db... >> %install-log%
  curl http://fastdl.mongodb.org/win32/mongodb-win32-x86_64-2.5.4.zip -o %temp-dir%\mongodb-setup.zip
goto instal_dev_environment

:ver_XP_64
  echo Sadly we can't support Windows XP... Please upgrade your OS! >> %install-log%
goto END

:instal_dev_environment
goto report_ok

:report_ok
  echo Installation of the Windows CodeCombat Developers environment succesfull... >> %install-log%
  echo Thank you in advance for your contribution! >> %install-log%
goto clean_up

:warn_and_exit
  echo Machine OS cannot be determined... >> %install-log%
  echo Report your OS to the developers @ CodeCombat.com... >> %install-log%
goto END


:: Clean Up The Mess
:clean_up
  rmdir %temp-dir% /s /q
goto END

:END

endlocal