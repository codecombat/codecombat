for /f "delims=" %%a in ('..\\utilities\\get_var.exe ..\\localisation\\%1.coco %2') do (
	set "%%a"
)