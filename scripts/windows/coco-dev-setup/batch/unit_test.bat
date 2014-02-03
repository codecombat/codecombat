@echo off
setlocal EnableDelayedExpansion

:: Global Variables
set "temp-dir=C:\Coco-Temp"
set install-log=%temp-dir%\coco-dev-install-log.txt

:: set correct curl app
IF EXIST "%PROGRAMFILES(X86)%" (
	(set "curl-app=utilities\curl\64bit\curl.exe")
) ELSE (
	(set "curl-app=utilities\curl\32bit\curl.exe")
)

set "ZU-app=utilities\7za.exe"

:: TODO:
::  + Write unpack and move code for software like mongo-db
::  + Write code to install vs if it's not yet installed on users pc
::  + Write Git Checkout repository code:
::      1) Let user specify destination
::      2) do a git clone with the git application
::  + Configuraton and installation checklist:
::      1) ... ?!
::  + Copy the automated dev batch file to root folder
::      => Let user define mongo-db directory
::  + Start the dev environment
::  + Exit message and warn user that he can quit the window now

set /p mongo_db_path="Enter db path: "
%ZU-app% x %temp-dir%\mongo-db-setup.zip -o%mongo_db_path% 
::move directory one up
::destroy that original root directory (remove)
PAUSE

:: ============================ INSTALL SOFTWARE FUNCTIONS ======================

:download_software
  call:get_lw word 4
  call:log "%word% %~1..."
  %curl-app% -sS -k %~2 -o %temp-dir%\%~1-setup.%~3
goto:eof

:install_software
  call:download_software %~1 %~2 %~3
  call:get_lw word 5
  call:log "%word% %~1..."
  START /WAIT %temp-dir%\%~1-setup.%~3
goto:eof

:install_software_o
  call:get_lw word %~4
  set /p result="%word% [Y/N]: "
  call:draw_dss
  set res=false
  if "%result%"=="N" set res=true
  if "%result%"=="n" set res=true
  if "%res%"=="true" (
    call:install_software %~1 %~2 %~3
  ) else (
    call:log_lw 10
  )
goto:eof

:install_packed_software
  call:download_software %~1 %~2 zip
  call:get_lw word 24
  call:log "%word% %~1..."
  ZU-app %temp-dir%\%~1-setup.zip
  ::what directory do you want to move it too?
goto:eof

:install_packed_software_o
  call:get_lw word %~3
  set /p result="%word% [Y/N]: "
  call:draw_dss
  set res=false
  if "%result%"=="N" set res=true
  if "%result%"=="n" set res=true
  if "%res%"=="true" (
    call:install_packed_software %~1 %~2
  ) else (
    call:log_lw 10
  )
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
  call:log "%str%"
goto:eof

:log_lw_ss
  call:get_lw str %~1
  call:log_ss "%str%"
goto:eof

:log_lw_ds
  call:get_lw str %~1
  call:log_ds "%str%"
goto:eof

:log_lw_sse
  call:get_lw str %~1
  call:log_sse "%str%"
goto:eof

:: ============================== EOF ====================================

:END
endlocal