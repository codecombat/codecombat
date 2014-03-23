@echo off
setlocal EnableDelayedExpansion

Color 0A
mode con: cols=78 lines=60

call print_header
call print_dashed_seperator

call get_config version
call get_config author
call get_config copyright
echo Welcome to the automated Installation of the CodeCombat Dev. Environment!
echo v%version% authored by %author% and published by %copyright%.

endlocal