@echo off
setlocal EnableDelayedExpansion

call configuration_cmd

call github_setup

start cmd /c "setup_p3.bat"

call write_cache.bat

call get_local_text switch_install switch install
call get_local_text switch_close switch close
call get_local_text switch_open switch open

echo %switch_install%
echo %switch_close%
echo.

set /p "dummy=%switch_open%"

endlocal