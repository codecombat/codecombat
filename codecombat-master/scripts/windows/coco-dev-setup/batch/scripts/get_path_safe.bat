goto:get_safe_path

:get_safe_path
	set /p "tmp_safe_path=%1"
	if not exist "%tmp_safe_path%" (
		call get_local_text error-exist
		echo !error_exist!
		call print_dashed_seperator
		goto:get_safe_path
	)