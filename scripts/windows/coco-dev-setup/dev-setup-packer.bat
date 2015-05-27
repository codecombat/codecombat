@echo off
setlocal EnableDelayedExpansion

:: ================= GLOBAL VARIABLES ===================
set "ZU-app=batch\utilities\7za.exe"
set "title=coco-dev-win-setup"

cd batch\\scripts\\
call get_config version
cd ..\\..\\

%ZU-app% a "%title%-%version%.zip" .\batch\*

:: =================== EOF =============================

endlocal