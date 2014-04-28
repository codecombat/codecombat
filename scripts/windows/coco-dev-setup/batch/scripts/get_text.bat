<<<<<<< HEAD
for /F "delims=" %%F in ('call run_script .\\get_var.ps1 ..\\localisation\\%1.coco %3 %4 %5 %6') do (
	set "%2=%%F"
=======
for /F "delims=" %%F in ('call run_script .\\get_var.ps1 ..\\localization\\%1.coco %3 %4 %5 %6') do (
	set "%2=%%F"
>>>>>>> 072729acc34123c42250d361955438cfd8c210d7
)