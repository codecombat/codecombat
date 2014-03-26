set "temp_directory=c:\.coco\"
set "curl_app=..\utilities\curl.exe"
set "zu_app=..\utilities\7za.exe"

if NOT exist "%temp_directory%" (
	md %temp_directory%
)

:: =================================================================
:: NOTE
:: -----------------------------------------------------------------
:: For now only mongodb is downloaded in packaged format
:: Mongodb doesn't require any packaging so we just hardcode
:: the exception in this file.

:: If we have ever another install file, that is packaged,
:: We'll have to make sure that mongodb is handled as an exception,
:: rather than that it's behaviour is the default for zip files.
:: =================================================================

call get_local_text install-process-prefix
call get_local_text install-process-sufix

call ask_question "!install_process_prefix! %1 !install_process_sufix!"
call print_dashed_seperator

if "%result%"=="false" (
	call get_extension %2 download_extension

	call get_local_text install-process-downloading
	echo %1 !install_process_downloading!
	set "install_file=%temp_directory%%1.%download_extension%"
	%curl_app% -k %2 -o !install_file!

	pause
	if "%1"=="mongodb" (
		pause
		call get_local_text install-process-unzipping
		echo %1 !install_process_unzipping!

		set "package_path=!temp_directory!%1\"
		if exist "!package_path!" (
			rmdir /s /q !package_path!
		)

		%zu_app% x %install_file% -o%package_path% -y

		for /f "delims=" %%a in ('dir %package_path% /on /ad /b') do @set mongodb_original_directory=%%a

		call print_dashed_seperator
		goto:get_mongodb_path

		:get_mongodb_path
			set /p "mongodb_path=define path: "
			if exist "%mongodb_path%" (
				call ask_question "That path already exists, are you sure you want to overwrite it?"
				if "%result%"=="false" (
					call print_dashed_seperator
					goto:get_mongodb_path
				) else (
					rmdir /s /q %mongodb_path%
				)
			)
			md %mongodb_path%
		)
		%systemroot%\System32\xcopy %mongodb_original_directory% %path% /r /h /s /e /y
		goto:clean_up
	) else (
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

		goto:clean_up
	)
)

:clean_up
	call get_local_text install-process-cleaning
	echo %1 !install_process_cleaning!
	rmdir /s /q "!temp_directory!"

	call print_dashed_seperator
goto:eof