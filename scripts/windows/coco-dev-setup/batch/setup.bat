@echo off
setlocal EnableDelayedExpansion

Color 0A
mode con: cols=78 lines=60

call print_header
call print_dashed_seperator

call get_config version
set "version=%temp_var%"
call get_config author
set "author=%temp_var%"
call get_config copyright
set "copyright=%temp_var%"
echo Welcome to the automated Installation of the CodeCombat Dev. Environment!
echo v%version% authored by %author% and published by %copyright%.

endlocal