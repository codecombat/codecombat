@echo off
setlocal EnableDelayedExpansion

Color 0A 

mode con: cols=78 lines=60

:: Global Variables
set "temp-dir=C:\Coco-Temp"
set install-log=%temp-dir%\coco-dev-install-log.txt

:: set correct curl app
IF EXIST "%PROGRAMFILES(X86)%" (
	(set "curl-app=utilities\curl\64bit\curl.exe")
) ELSE (
	set "curl-app=utilities\curl\32bit\curl.exe"
)

set "ZU-app=utilities\7za.exe"

:: TODO:

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
	
:: Create The Temporary Directory
IF EXIST %temp-dir% rmdir %temp-dir% /s /q
mkdir %temp-dir%

:: Create Log File
copy /y nul %install-log% > nul

call:parse_aa_and_draw "config\header"
call:draw_dss

call:parse_file_new "config\config" cnfg n

call:log "Welcome to the automated Installation of the CodeCombat Dev. Environment!"
call:log_sse "v%%cnfg[1]%% authored by %%cnfg[2]%% and published by %%cnfg[3]%%."

:: Language Agreement Stuff

call:log "In order to continue the installation of the developers environment"
call:log "you will have to read and agree with the following license:
call:draw_dss
echo.
call:parse_aa_and_draw "license.txt"
echo.
call:draw_dss
call:strict_user_yn_question "Have you read the license and do you agree with it?"  

if "%res%"=="false" (
  call:log "Sorry to hear that, have a good day..."
  call:log_sse "Installation and Setup of the CodeCombat environment is cancelled."
  GOTO:END
)

:: Read Language Index
call:parse_file_new "localisation\languages" lang lang_c

:: Read Download URLs
call:parse_file_new "config\downloads" downloads n
call:parse_file_new "config\downloads_32" downloads_32 n
call:parse_file_new "config\downloads_64" downloads_64 n
call:parse_file_new "config\downloads_vista_32" downloads_vista_32 n
call:parse_file_new "config\downloads_vista_64" downloads_vista_64 n
call:parse_file_new "config\downloads_7_32" downloads_7_32 n
call:parse_file_new "config\downloads_7_64" downloads_7_64 n

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

set "lang_id=-1"
call:user_enter_language_id
goto:user_pick_language

:user_enter_language_id
  set /p lang_id= "Enter the language ID and press <ENTER>: "
goto:eof

:user_pick_language
  set res=false
  if %lang_id% LSS 0 set res=true
  if %lang_id% GEQ %lang_c% set res=true
  if "%res%"=="true" (
    call:log "Invalid id! Please enter a correct id from the numbers listed above..."
    call:draw_dss
    call:user_enter_language_id
    goto:user_pick_language
  )
  
call:get_lw word 0
call:log_ds "You choose '%word%', from now on all feedback will be logged in it."
  
call:log_lw 1
call:log_lw_sse 2

:: downloads for all version...

:: [TODO] The choice between Cygwin && Git ?! Is  => HAVE EXTERNAL GIT APPLICATION LIST!!!

call:log_lw_sse 3

call:log_lw 6
call:log_lw 7
call:log_lw 8
call:install_software_o "git" "%%downloads[1]%%" exe 9
call:draw_dss
call:get_lw word 11
:: [TODO] Check if that application exists, if not ask again with warning that the path is invalid!!! (SAFETYYYY)

set git_exe="bin\sh.exe"

:: [TODO] Add downloads for windows visual studio ?!

call:user_set_git_path

:user_set_git_path_fail
  if not exist "%git_exe_path%" (
    call:log_lw 27
    call:draw_dss
    call:user_set_git_path
  )
  :: architecture specific downloads...
  IF EXIST "%PROGRAMFILES(X86)%" (GOTO 64BIT) ELSE (GOTO 32BIT)
goto:eof

:user_set_git_path
  set /p git_exe_path="%word%: "
  call:user_set_git_path_fail
goto:eof

:go_to_platform
  call:log_ds "Windows %~1 detected..."
  GOTO %~2
goto:eof

:64BIT
  call:log_ds "64-bit computer detected..."
  
  call:install_software_o "node-js" "%%downloads_64[1]%%" msi 12
  call:draw_dss
  call:install_software_o "ruby" "%%downloads_64[2]%%" exe 13
  call:draw_dss
  call:install_software_o "python" "%%downloads_64[3]%%" msi 26
  
  :: Some installations require specific windows versions
  for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
  if "%version%" == "5.2" ( call:go_to_platform "XP" ver_XP_64 )
  if "%version%" == "6.0" ( call:go_to_platform "Vista" ver_Vista_64 )
  if "%version%" == "6.1" ( call:go_to_platform "7" ver_Win7_8_64 )
  if "%version%" == "6.2" ( call:go_to_platform "8.0" ver_Win7_8_64 )
  if "%version%" == "6.3" ( call:go_to_platform "8.1" ver_Win7_8_64 )
  GOTO warn_and_exit
GOTO END

:32BIT
  call:log_ds "32-bit computer detected..."
  
  call:install_software_o "node-js" "%%downloads_32[1]%%" msi 12
  call:draw_dss
  call:install_software_o "ruby" "%%downloads_32[2]%%" exe 13
  call:draw_dss
  call:install_software_o "python" "%%downloads_32[3]%%" msi 26
  
  :: Some installations require specific windows versions
  for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
  if "%version%" == "5.2" ( call:go_to_platform "XP" ver_XP_32 )
  if "%version%" == "6.0" ( call:go_to_platform "Vista" ver_Vista_32 )
  if "%version%" == "6.1" ( call:go_to_platform "7" ver_Win7_8_32 )
  if "%version%" == "6.2" ( call:go_to_platform "8.0" ver_Win7_8_32 )
  if "%version%" == "6.3" ( call:go_to_platform "8.1" ver_Win7_8_32 )
  GOTO warn_and_exit
GOTO END

:ver_Win7_8_32
  call:install_packed_software_o "mongo-db" "%%downloads_7_32[1]%%" 25 14
  set "mong-db-path = %packed_software_path%"
goto git_rep_checkout

:ver_Vista_32
  call:install_packed_software_o "mongo-db" "%%downloads_vista_32[1]%%" 25 14
  set "mong-db-path = %packed_software_path%"
goto git_rep_checkout

:ver_XP_32
  call:log_lw_ds 15
goto END

:ver_Win7_8_64
  call:install_packed_software_o "mongo-db" "%%downloads_7_64[1]%%" 25 14
  set "mong-db-path = %packed_software_path%"
goto git_rep_checkout

:ver_Vista_64
  call:install_packed_software_o "mongo-db" "%%downloads_vista_64[1]%%" 25 14
  set "mong-db-path = %packed_software_path%"
goto git_rep_checkout

:ver_XP_64
  call:log_lw_ds 15
goto END

:git_rep_checkout
  call:log_lw_ss 16
  call:log_lw_sse 17
  
  ::Show user the correct steps to execute
  call:log_lw 28
  call:log_lw_prfx 29 "  1) "
  call:log_lw_prfx 30 "      "
  call:log_lw_prfx 31 "  2) "
  
  call:draw_dss
  start /WAIT "%git_exe_path%\%git_exe% --login -i" 
  call:draw_dss
  
  call:user_set_git_repository
goto git_repo_configuration

:user_set_git_repository
  call:get_lw word 32
  set /p git_repository_path="%word% "
  call:user_set_git_repository_sc
goto:eof

:user_set_git_repository_sc
  if not exist "%git_repository_path%" (
    call:log_lw 33
    call:draw_dss
    call:user_set_git_repository
  )
  goto git_repo_configuration
goto:eof

:git_repo_configuration
  call:log_lw_ss 35
  call:log_lw_sse 36
goto report_ok

:report_ok
  call:log_lw 18
  call:log_lw_sse 19
  
  :: Open README file
  call:open_readme
  
goto clean_up

:open_readme
  call:open_txt_file "config/info"
goto:eof

:warn_and_exit
  call:log_lw_ss 20
  call:log_lw_sse 21
goto error_report

:error_report
  call:log_lw_ds 22
goto END

:clean_up
  call:log_lw_sse 23
  rmdir %temp-dir% /s /q
  PAUSE
goto END

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
  call:user_yn_question "%word%"
  if "%res%"=="true" (
    call:install_software %~1 %~2 %~3
  ) else (
    call:log_lw 10
  )
goto:eof

:install_packed_software
  call:download_software %~1 %~2 zip
  
  call:draw_dss
  
  call:get_lw word %~3
  
  set /p packed_software_path="%word% "
  
  :: remove chosen directory of user if it already exists (to prevent a window from popping up)
  IF EXIST %packed_software_path% rmdir %packed_software_path% /s /q
  
  %ZU-app% x %temp-dir%\%~1-setup.zip -o%packed_software_path%
  
  call:draw_dss

  for /f "delims=" %%a in ('dir "%packed_software_path%\" /on /ad /b') do @set temp_dir=%%a
  for /f "delims=" %%a in ('dir "%packed_software_path%\%temp_dir%\" /on /ad /b') do (
    xcopy %packed_software_path%\%temp_dir% %packed_software_path%\ /S /E
  )
  
  call:draw_dss
  rmdir %packed_software_path%\%temp_dir%\ /s /q
goto:eof

:user_yn_question
  set /p result="%~1 [Y/N]: "
  call:draw_dss
  set "res=false"
  if "%result%"=="N" (set "res=true")
  if "%result%"=="n" (set "res=true")
goto:eof

:strict_user_yn_question
  set /p result="%~1 [Y/N]: "
  call:draw_dss
  set "res=unset"
  if "%result%"=="N" (set "res=false")
  if "%result%"=="n" (set "res=false")
  if "%result%"=="Y" (set "res=true")
  if "%result%"=="y" (set "res=true")
  
  if "%res%"=="unset" (
    call:log "Please answer the question with either Y or N..."
    call:draw_dss
    call:strict_user_yn_question "%~1"
  )
goto:eof

:install_packed_software_o
  call:get_lw word %~4
  call:user_yn_question "%word%"
  if "%res%"=="true" (
    call:install_packed_software %~1 %~2 %~3
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
  echo.
  call:log "-----------------------------------------------------------------------------"
  echo.
goto:eof

:draw_dss
  echo.
  call:log "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  echo.
goto:eof

:draw_seperator
  echo.
  echo                            + + + + + + + +                           
  echo.
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

:open_txt_file
  start "" notepad.exe %~1
goto:eof

:parse_aa_and_draw
  set "file=%~1"
  for /f "usebackq tokens=* delims=;" %%a in ("%file%") do (
    echo.%%a
  )
goto:eof

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

:: ============================== LOCALISATION FUNCTIONS ================

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

:log_lw_prfx
  call:get_lw str %~1
  call:log "%~2%str%"
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

:: ============================== WINDOWS FUNCTIONS ======================

:set_env_var
  setx -m %~1 %~2
goto:eof

:: ============================== EOF ====================================

:END
  set /p input="You can close this window now..."
endlocal