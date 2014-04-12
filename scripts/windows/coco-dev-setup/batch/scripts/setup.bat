<<<<<<< HEAD
@echo off
setlocal EnableDelayedExpansion

Color 0A
mode con: cols=79 lines=55

call print_header
call print_dashed_seperator

call get_config.bat version
call get_config.bat author
call get_config.bat copyright
echo Welcome to the automated Installation of the CodeCombat Dev. Environment!
echo v%version% authored by %author% and published by %copyright%.
call print_seperator

echo Before we start the installation, here are some tips:
call print_tips
call print_seperator

call sign_license

call get_language

call download_and_install_applications

call github_setup

:: This will be available in v2.0
::call npm_and_brunch_setup

call print_finished_header
call print_dashed_seperator

call get_local_text end_succesfull end succesfull
call get_local_text end_thankyou end thankyou
echo %end_succesfull%
echo %end_thankyou%

call print_dashed_seperator

call get_local_text start_s1 start s1
call get_local_text start_s2 start s2
call get_local_text start_s3 start s3
call get_local_text start_s4 start s4
call get_local_text start_s5 start s5
call get_local_text start_s6 start s6

echo !start_s1!
echo !start_s2!
echo.
echo !start_s3! '!repository_path!\coco\SCOCODE.bat'
echo !start_s4!
echo !start_s5!
echo.
echo !start_s6!

call print_dashed_seperator

call get_local_text end_readme end readme
call ask_question "!end_readme!"

if "%result%"=="true" (
	call open_readme
)

=======
@echo off
setlocal EnableDelayedExpansion

call configuration_cmd

call print_header
call print_dashed_seperator

call get_config.bat version
call get_config.bat author
call get_config.bat copyright
echo Welcome to the automated Installation of the CodeCombat Dev. Environment!
echo v%version% authored by %author% and published by %copyright%.
call print_seperator

call get_language

call get_local_text global_tips global tips
echo !global_tips!
call print_tips
call print_seperator

call sign_license

call download_and_install_applications

start cmd /c "setup_p2.bat"

>>>>>>> 072729acc34123c42250d361955438cfd8c210d7
endlocal