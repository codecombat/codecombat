for /F "delims=" %%F in ('call run_script .\\get_var.ps1 ..\\config\\downloads.coco %2 %3 %4 %5') do (
	set "%1=%%F"
)