set "temp_directory=c:\.coco\"
set "curl_app=..\utilities\curl.exe"
set "zu_app=..\utilities\7za.exe"

if NOT exist "%temp_directory%" (
	md %temp_directory%
)

call get_local_text install-process-prefix
call get_local_text install-process-sufix

call ask_question "!install_process_prefix! %1 !install_process_sufix!"

if "%result%"=="true" (
	goto:exit_installation
)

call print_dashed_seperator

call get_extension %2 download_extension
call get_local_text install-process-downloading
echo %1 !install_process_downloading!
set "install_file=!temp_directory!%1.!download_extension!"
%curl_app% -k %2 -o !install_file!

if "%download_extension%"=="zip" (
	set "package_path=!temp_directory!%1\"

	%zu_app% x !install_file! -o!package_path! -y

	for /f "delims=" %%a in ('dir !package_path! /on /ad /b') do @set mongodb_original_directory=%%a

	call print_dashed_seperator
	goto:get_mongodb_path

	:get_mongodb_path
		call get_local_text install-process-mongodbpath
		set /p "mongodb_path=!install_process_mongodbpath!: "
		if exist "%mongodb_path%" (
			call get_local_text error-path
			call ask_question "!error_path!"
			if "!result!"=="false" (
				call print_dashed_seperator
				goto:get_mongodb_path
			) else (
				rmdir /s /q %mongodb_path%
			)
		)
	md %mongodb_path%

	%systemroot%\System32\xcopy !package_path!!mongodb_original_directory! !mongodb_path! /r /h /s /e /y
	goto:clean_up
)

call get_local_text install-process-installing
echo %1 !install_process_installing!
echo.
start /WAIT !install_file!
goto:clean_up

:clean_up
	call get_local_text install-process-cleaning
	echo %1 !install_process_cleaning!
	rmdir /s /q "!temp_directory!"
	goto:exit_installation

:exit_installation
	call print_dashed_seperator