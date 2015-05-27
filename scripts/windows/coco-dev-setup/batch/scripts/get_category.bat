for /f "delims=" %%a in ('..\\utilities\\get_category.exe %*') do (
	%%a
)