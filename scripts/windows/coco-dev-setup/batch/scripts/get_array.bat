set "file=%1"
set /a %3=0
for /F "usebackq delims=" %%a in ("%file%") do (
	set /A %3+=1
	call set %2[%%%3%%]=%%a
)