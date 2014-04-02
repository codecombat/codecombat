for /f "delims=" %%a in ('..\\utilities\\get_extension.exe %1 %2') do (
	%%a
)