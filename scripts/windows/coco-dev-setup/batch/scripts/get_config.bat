for /F "delims=" %%F in ('call run_script .\\get_var.ps1 ..\\config\\config.coco %1') do (
	set "%1=%%F"
)