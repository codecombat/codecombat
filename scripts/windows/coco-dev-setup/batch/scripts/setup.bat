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

echo Before we start the installation, here are some tips:
call print_tips
call print_seperator

call sign_license

call get_language

call download_and_install_applications

start cmd /c "setup_p2.bat"

endlocal