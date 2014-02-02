@echo off
setlocal

:: Global Variables
set "temp-dir=C:\Coco-Temp"
set install-log=%temp-dir%\coco-dev-install-log.txt

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

call:log "Full-Automatic Install of the CodeCombat Dev. Environment has begun..."
call:log "This can take a while... Please stay tuned..."
call:log_sse "Don't close any windows please...!"

:: downloads for all version...

:: [TODO] The choice between Cygwin && Git ?! Is 

call:log_sse "[DOWNLOADING AND INSTALLING 3RD PARTY SOFTWARE]"

call:install_software "git" "http://msysgit.googlecode.com/files/Git-1.8.5.2-preview20131230.exe"

:: [TODO] Add downloads for windows visual studio ?!

:: architecture specific downloads...
IF EXIST "%PROGRAMFILES(X86)%" (GOTO 64BIT) ELSE (GOTO 32BIT)

:go_to_platform
  call:log_ds "Windows %~1 detected..."
  GOTO %~2
goto:eof

:instal_swv_software
  :: Some installations require specific windows versions
  for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
  if "%version%" == "5.2" ( call:go_to_platform "XP" ver_XP_%~1 )
  if "%version%" == "6.0" ( call:go_to_platform "Vista" ver_Vista_%~1 )
  if "%version%" == "6.1" ( call:go_to_platform "7" ver_Win7_8_%~1 )
  if "%version%" == "6.2" ( call:go_to_platform "8.0" ver_Win7_8_%~1 )
  if "%version%" == "6.3" ( call:go_to_platform "8.1" ver_Win7_8_%~1 )
  GOTO warn_and_exit
goto:eof

:64BIT
  call:log_ds "64-bit computer detected..."
  
  call:install_software "node-js" "http://nodejs.org/dist/v0.10.24/x64/node-v0.10.24-x64.msi"
  call:draw_dss
  call:install_software "ruby" "http://dl.bintray.com/oneclick/rubyinstaller/rubyinstaller-2.0.0-p353-x64.exe?direct"
  
  instal_swv_software 64
GOTO END

:32BIT
  call:log_ds "32-bit computer detected..."
  
  call:install_software "node-js" "http://nodejs.org/dist/v0.10.24/node-v0.10.24-x86.msi"
  call:draw_dss
  call:install_software "ruby" "http://dl.bintray.com/oneclick/rubyinstaller/rubyinstaller-2.0.0-p353.exe?direct"
  
  instal_swv_software 32
GOTO END

:ver_Win7_8_32
  call:install_packed_software "mongo-db" "http://fastdl.mongodb.org/win32/mongodb-win32-i386-2.5.4.zip"
goto git_rep_checkout

:ver_Vista_32
  call:install_packed_software "mongo-db" "http://fastdl.mongodb.org/win32/mongodb-win32-i386-2.5.4.zip"
goto git_rep_checkout

:ver_XP_32
  call:log_ds "Sadly we can't support Windows XP... Please upgrade your OS!"
goto END

:ver_Win7_8_64
  call:install_packed_software "mongo-db" "http://fastdl.mongodb.org/win32/mongodb-win32-x86_64-2008plus-2.5.4.zip"
goto git_rep_checkout

:ver_Vista_64
  call:install_packed_software "mongo-db" "http://fastdl.mongodb.org/win32/mongodb-win32-x86_64-2.5.4.zip"
goto git_rep_checkout

:ver_XP_64
  call:log_ds "Sadly we can't support Windows XP... Please upgrade your OS!"
goto END

:git_rep_checkout
  call:log_ss "Software has been installed..."
  call:log_sse "Checking out the Git Repository..."
goto report_ok

:report_ok
  call:log_ss "Installation of the Developers Environment is complete!"
  call:log_sse "Bye Bye!"
goto clean_up

:warn_and_exit
  call:log_ss "Machine OS cannot be determined..."
  call:log_sse "Report your OS to the developers @ CodeCombat.com..."
goto error_report

:error_report
  call:log_ds "Installation has been stopped..."
goto END

:clean_up
  call:log_sse "... Cleaning up has been disabled... Terminating Script!"
  rmdir %temp-dir% /s /q
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

:draw_ss
  call:log "----------------------------------------------------------------------------"
goto:eof

:draw_dss
  call:log "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
goto:eof

:log_ss
  call:draw_ss
  call:log "%~1"
goto:eof

:log_sse
  call:log "%~1"
  call:draw_ss
goto:eof

:log_ds
  call:log_ss "%~1"
  call:draw_ss
goto:eof

:END
endlocal