for /F "delims=" %%F in ('call run_script .\\get_extension.ps1 %1') do (
	set "%2=%%F"
)