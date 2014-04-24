for /F "delims=" %%F in ('call run_script .\\get_var.ps1 ..\\localization\\%1.coco %3 %4 %5 %6') do (
	set "%2=%%F"
)