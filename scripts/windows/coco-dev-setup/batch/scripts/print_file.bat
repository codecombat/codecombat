set "file=%1"
for /f "usebackq tokens=* delims=;" %%a in ("%file%") do (
	echo.%%a
)