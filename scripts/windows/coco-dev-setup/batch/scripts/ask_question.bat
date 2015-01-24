set /p res="%1 [Y/N]: "
set "result=unset"
if "%res%"=="Y" (set "result=true")
if "%res%"=="y" (set "result=true")
if "%result%"=="unset" (set "result=false")