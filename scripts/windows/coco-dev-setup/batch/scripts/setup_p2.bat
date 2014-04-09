@echo off
setlocal EnableDelayedExpansion

call configuration_cmd

call github_setup

start cmd /c "setup_p3.bat"

endlocal