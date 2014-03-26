@echo off
setlocal EnableDelayedExpansion
set "temp_directory=c:\.coco\"
set "curl_app=..\utilities\curl.exe"
set "zu_app=..\utilities\7za.exe"

set "install_file=c:\.coco\mongodb.zip"
set "package_path=%temp_directory%mongodb"

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

pause

endlocal