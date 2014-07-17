set count=0
for /F "delims=" %%F in ('call run_script.bat .\\get_variables.ps1 %*') do (
	%%F
)