@echo off
setlocal EnableDelayedExpansion

:: Global Variables
set "temp-dir=C:\Coco-Temp"
set install-log=%temp-dir%\coco-dev-install-log.txt

:: set correct curl app
IF EXIST "%PROGRAMFILES(X86)%" (
	(set "curl-app=curl\64bit\curl.exe")
) ELSE (
	set "curl-app=curl\32bit\curl.exe"
)

:: TIPS
:: 	+ Ask user if he wants to install something
::	+ Ask user to enter the path of the installed program (git, ...)
	
:: Create The Temporary Directory
IF EXIST %temp-dir% rmdir %temp-dir% /s /q
mkdir %temp-dir%

:: Create Log File
copy /y nul %install-log% > nul

call:log_sse "Welcome to the automated Installation of the CodeCombat Dev. Environment!"

:: Read Language Index
call:parse_file_new "localisation\languages" lang lang_c

:: Parse all Localisation Files
for /L %%i in (1,1,%lang_c%) do (
  call:parse_file "localisation\%%lang[%%i]%%" languages languages_c
)

set /A "wc = %languages_c% / %lang_c%"

:: Start install with language question (Localisation)
call:log "Which language do you prefer?"

set /A c=0
for /L %%i in (1,%wc%,%languages_c%) do (
  set /A "n = %%i - 1"
  call:log "  [%%c%%] %%languages[%%i]%%"
  set /A c+=1
)

set /p lang_id= "Enter the language ID and press <ENTER>: "

call:log_lw_ss 1
call:log_lw_sse 2

:: downloads for all version...

:: [TODO] The choice between Cygwin && Git ?! Is 

call:log_lw_sse 3

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
  call:get_lw word 4
  call:log "%word% %~1..."
  %curl-app% %~2 -o %temp-dir%\%~1-setup.exe
  call:get_lw word 5
  call:log "%word% %~1..."
  START /WAIT %temp-dir%\%~1-setup.exe
goto:eof

:: ============================== FUNCTIONS ====================================

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

:: ============================== IO FUNCTIONS ====================================

:parse_file
  set "file=%~1"
  for /F "usebackq delims=" %%a in ("%file%") do (
    set /A %~3+=1
    call set %~2[%%%~3%%]=%%a
  )
goto:eof

:parse_file_new
  set /A %~3=0
  call:parse_file %~1 %~2 %~3
goto:eof

:: ============================== LOCALISATION FUNCTIONS ===========================

:get_lw
  call:get_lw_id %~1 %lang_id% %~2
goto:eof

:get_lw_id
  set /A count = %~2 * %wc% + %~3 + 1
  set "%~1=!languages[%count%]!"
goto:eof

:log_lw
  call:get_lw str %~1
  call:log %str%
goto:eof

:log_lw_ss
  call:get_lw str %~1
  call:log_ss %str%
goto:eof

:log_lw_ds
  call:get_lw str %~1
  call:log_ds %str%
goto:eof

:log_lw_sse
  call:get_lw str %~1
  call:log_sse %str%
goto:eof

:: ============================== EOF ====================================

:END
endlocal