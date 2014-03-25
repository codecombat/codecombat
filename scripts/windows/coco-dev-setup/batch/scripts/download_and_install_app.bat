set "temp_directory=c:\\.coco\\"
set "curl_app=..\\utilities\\curl.exe"
set "zu_app=..\\utilities\\7za.exe"

if NOT exist "%temp_directory%" (
	md %temp_directory%
)

call get_local_text install-process-prefix
call get_local_text install-process-sufix

call ask_question "!install_process_prefix! %1 !install_process_sufix!"
call print_dashed_seperator

if "%result%"=="false" (
	get_extension %2 download_extension

	call get_local_text install-process-downloading
	echo %1 !install_process_downloading!
	set "install_file=!temp_directory!%1.!download_extension!"
	%curl_app% -k %2 -o !install_file!

	if "%download_extension%"=="zip" (
		call get_local_text install-process-unzipping
		echo %1 !install_process_unzipping!

		set "package_path=!temp_directory!%1\\"
		if exist "!package_path!" (
			rmdir /s /q !package_path!
		)

		%zu_app% x !install_file! -o!package_path!
		pause
	)

	call get_local_text install-process-installing
	echo %1 !install_process_installing!
	echo.
	if "%download_extension%"=="zip" (
		for /f "tokens=*" %%a in ( dir %package_path% /b *.exe' ) do ( 
			set unpacked_installed_file=%%a 
		)
		start /WAIT %unpacked_installed_file%
	) else (
		start /WAIT !install_file!
	)
)

call get_local_text install-process-cleaning
echo %1 !install_process_cleaning!
rmdir /s /q "!temp_directory!"

call print_dashed_seperator