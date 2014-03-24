set "temp_directory=C:\\.coco\\"

if NOT exist "%temp_directory%" (
	md "%temp_directory%"
)



rmdir /s /q "%temp_directory%"