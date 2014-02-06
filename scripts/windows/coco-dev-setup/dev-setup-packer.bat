@echo off
setlocal EnableDelayedExpansion

:: ================= GLOBAL VARIABLES ===================
set "ZU-app=batch\utilities\7za.exe"
set "title=coco-dev-win-setup"

call:parse_file_new "batch\config\config" cnfg n
set "sf=%cnfg[1]%"

%ZU-app% a "%title%-%sf%.zip" .\batch\*


:: ================= FUNCTIONS =========================

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

:: =================== EOF =============================

endlocal