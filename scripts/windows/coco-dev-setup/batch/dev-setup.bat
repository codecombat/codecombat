@echo off
setlocal

:: Global Variables
set "temp-dir=C:\Coco-Temp"
set install-log=%temp-dir%\coco-dev-install-log.txt
set "tab-string=      "
set "seperator-string=----------------------------------------------------------------------------"
set "seperator-string-cmd=-------------------------------------------"

:: set correct curl app
IF EXIST "%PROGRAMFILES(X86)%" (
	(set "curl-app=curl\64bit\curl.exe")
) ELSE (
	set "curl-app=curl\32bit\curl.exe"
)
	
:: Create The Temporary Directory
IF EXIST %temp-dir% rmdir %temp-dir% /s /q
mkdir %temp-dir%

:: Create Log File
copy /y nul %install-log% > nul

echo Full-Automatic Install of the CodeCombat Dev. Environment has begun...
echo This can take a wile... Please stay tuned...
echo Don't close any windows please...!
echo %seperator-string-cmd%

echo %seperator-string% >> %install-log%
echo Full-Automatic Install has begun... Don't close any windows please! >> %install-log%
echo %seperator-string% >> %install-log%

:: downloads for all version...

:: [TODO] The choice between Cygwin && Git ?! Is 

echo downloading: Git... >> %install-log%
echo %seperator-string% >> %install-log%

call:install_software git "http://msysgit.googlecode.com/files/Git-1.8.5.2-preview20131230.exe"

:: [TODO] Add downloads for windows visual studio ?!


:: architecture specific downloads...
IF EXIST "%PROGRAMFILES(X86)%" (GOTO 64BIT) ELSE (GOTO 32BIT)

:64BIT
  echo 64-bit computer detected... >> %install-log%
  
  echo %tab-string%downloading: node-js... >> %install-log%
  %curl-app% http://nodejs.org/dist/v0.10.24/x64/node-v0.10.24-x64.msi -o %temp-dir%\node-js-setup.exe

  echo %tab-string%downloading: ruby... >> %install-log%
  %curl-app% http://dl.bintray.com/oneclick/rubyinstaller/rubyinstaller-2.0.0-p353-x64.exe?direct -o %temp-dir%\ruby-setup.exe
  
  :: Some installations require specific windows versions
  for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
  if "%version%" == "5.2" (
    echo %tab-string%Windows XP detected... >> %install-log%
    GOTO ver_XP_64
  )
  if "%version%" == "6.0" (
    echo %tab-string%Windows Vista detected... >> %install-log%
    GOTO ver_Vista_64
  )
  if "%version%" == "6.1" (
    echo %tab-string%Windows 7 detected... >> %install-log%
    GOTO ver_Win7_8_64
  )
  if "%version%" == "6.2" (
    echo %tab-string%Windows 8.0 detected... >> %install-log%
    GOTO ver_Win7_8_64
  )
  if "%version%" == "6.3" (
    echo %tab-string%Windows 8.1 detected... >> %install-log%
    GOTO ver_Win7_8_64
  )
  
  GOTO warn_and_exit
GOTO END

:32BIT
  echo 32-bit computer detected... >> %install-log%
  
  echo %tab-string%downloading: node-js... >> %install-log%
  echo %tab-string%downloading: node-js...
  %curl-app% http://nodejs.org/dist/v0.10.24/node-v0.10.24-x86.msi -o %temp-dir%\node-js-setup.exe
  
  echo %tab-string%downloading: ruby... >> %install-log%
  echo %tab-string%downloading: ruby...
  %curl-app% http://dl.bintray.com/oneclick/rubyinstaller/rubyinstaller-2.0.0-p353.exe?direct -o %temp-dir%\ruby-setup.exe
  
  :: Some installations require specific windows versions
  for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
  
  if "%version%" == "5.1" (
    echo %tab-string%Windows XP detected... >> %install-log%
    GOTO ver_XP_32
  )
  if "%version%" == "6.0" (
    echo %tab-string%Windows Vista detected... >> %install-log%
    GOTO ver_Vista_32
  )
  if "%version%" == "6.1" (
    echo %tab-string%Windows 7 detected... >> %install-log%
    GOTO ver_Win7_8_32
  )
  if "%version%" == "6.2" (
    echo %tab-string%Windows 8.0 detected... >> %install-log%
    GOTO ver_Win7_8_32
  )
  if "%version%" == "6.3" (
    echo %tab-string%Windows 8.1 detected... >> %install-log%
    GOTO ver_Win7_8_32
  )
  
  GOTO warn_and_exit
GOTO END

:ver_Win7_8_32
  echo %tab-string%%tab-string%downloading: mongo-db... >> %install-log%
  %curl-app% http://fastdl.mongodb.org/win32/mongodb-win32-i386-2.5.4.zip -o %temp-dir%\mongodb-setup.zip
goto instal_dev_environment

:ver_Vista_32
  echo %tab-string%%tab-string%downloading: mongo-db... >> %install-log%
  %curl-app% http://fastdl.mongodb.org/win32/mongodb-win32-i386-2.5.4.zip -o %temp-dir%\mongodb-setup.zip
goto instal_dev_environment

:ver_XP_32
  echo %seperator-string% >> %install-log%
  echo Sadly we can't support Windows XP... Please upgrade your OS! >> %install-log%
  echo %seperator-string% >> %install-log%
goto END

:ver_Win7_8_64
  echo %tab-string%%tab-string%downloading: mongo-db... >> %install-log%
  %curl-app% http://fastdl.mongodb.org/win32/mongodb-win32-x86_64-2008plus-2.5.4.zip -o %temp-dir%\mongodb-setup.zip
goto instal_dev_environment

:ver_Vista_64
  echo %tab-string%%tab-string%downloading: mongo-db... >> %install-log%
  %curl-app% http://fastdl.mongodb.org/win32/mongodb-win32-x86_64-2.5.4.zip -o %temp-dir%\mongodb-setup.zip
goto instal_dev_environment

:ver_XP_64
  echo %seperator-string% >> %install-log%
  echo Sadly we can't support Windows XP... Please upgrade your OS! >> %install-log%
  echo %seperator-string% >> %install-log%
goto END

:instal_dev_environment
  echo %seperator-string-cmd%
  echo Downloads complete...
  echo Installation of the software begins now...
  echo %seperator-string-cmd%
  
  echo %seperator-string% >> %install-log%
  echo Downloads complete... Moving on to the installation! >> %install-log%
  echo %seperator-string% >> %install-log%
  
  :: install node-js
  start "" "%temp-dir%\git-setup.exe"
  start "" "%temp-dir%\node-js-setup.exe"
  PAUSE
goto git_rep_checkout

:git_rep_checkout
  echo %seperator-string-cmd%
  echo Software has been installed...
  echo Checking out the Git Repository....
  echo %seperator-string-cmd%
  
  echo %seperator-string% >> %install-log%
  echo Software Installations Complete... Moving on to the Code Combat Repository Checkout! >> %install-log%
  echo %seperator-string% >> %install-log%
goto report_ok

:report_ok
  echo %seperator-string-cmd%
  echo Installation of the Developers Environment is complete!
  echo Bye Bye!
  echo %seperator-string-cmd%
  
  echo %seperator-string% >> %install-log%
  echo Installation of the Windows CodeCombat Developers environment succesfull... >> %install-log%
  echo Thank you in advance for your contribution! >> %install-log%
  echo %seperator-string% >> %install-log%
goto clean_up

:warn_and_exit
  echo %seperator-string-cmd%
  echo OS Cannot be determined...
  echo %seperator-string-cmd%
  
  echo %seperator-string% >> %install-log%
  echo Machine OS cannot be determined... >> %install-log%
  echo Report your OS to the developers @ CodeCombat.com... >> %install-log%
  echo %seperator-string% >> %install-log%
goto error_report

:error_report
  echo Installation has been stopped...
  echo Please check the log file for details!
  PAUSE
goto END

:: Clean Up The Mess
:clean_up
  echo ... Cleaning up has been disabled... Terminating Script! >> %install-log%
  echo %seperator-string% >> %install-log%
  ::rmdir %temp-dir% /s /q
goto END

:install_software
call:log "downloading: %~1..."
%curl-app% %~2 -o %temp-dir%\%~1-setup.exe
call:log "installing: %~1..."
START /WAIT %temp-dir%\%~1-setup.exe
goto:eof

:log
echo %~1
echo %~1 >> %install-log%
goto:eof

:END
PAUSE
endlocal