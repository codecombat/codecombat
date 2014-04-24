call print_github_header
call print_dashed_seperator

call get_local_text github_intro_opensource github intro opensource
call get_local_text github_intro_online github intro online
call get_local_text github_intro_manual github intro manual
call get_local_text github_intro_norec github intro norec

echo !github_intro_opensource!
echo !github_intro_online!
echo !github_intro_manual!
echo !github_intro_norec!

call print_dashed_seperator

call get_local_text github_skip_question github skip question
call ask_question "!github_skip_question!"
call print_dashed_seperator

if "%result%"=="true" (
	call get_local_text github_skip_consequence github skip consequence
	echo !github_skip_consequence!

	call get_local_text github_skip_donotclose github skip donotclose
	echo !github_skip_donotclose!

	call get_local_text github_skip_wait github skip wait
	set /p "github_skip_wait=!github_skip_wait!"

	call print_dashed_seperator

	call get_local_text github_process_path github process path
	call get_path_safe "!github_process_path!"
	set "repository_path=!tmp_safe_path!"

	goto:exit_git_setup
)

goto:get_bash_path

:get_bash_path
	call get_local_text github_process_bashi github process bashi
	echo !github_process_bashi!

	if not defined install_system_bit (
		call print_dashed_seperator
		call get_system_information
		call print_dashed_seperator
	)

	if "%system_info_bit%"=="64" (
		call get_local_text github_process_bashp64 github process bashp64
		echo !github_process_bashp64!
	) else (
		call get_local_text github_process_bashp32 github process bashp32
		echo !github_process_bashp32!
	)

	call get_local_text github_process_bashq github process bashq
	set /p "git_bash_path=!github_process_bashq!: "

	if not defined git_bash_path (
		if "%system_info_bit%"=="64" (
			set "git_bash_path=C:\Program Files (x86)\Git"
		) else (
			set "git_bash_path=C:\Program Files\Git"
		)
		goto:get_git_path
	)

	if not exist "%git_bash_path%" (
		call get_local_text error_exist error exist
		echo !error_exist!
		call print_dashed_seperator
		goto:get_bash_path
	) else (
		goto:get_git_path
	)
goto:eof

:get_git_path
	call print_dashed_seperator
	call get_local_text github_process_checkout github process checkout
	set /p "repository_path=!github_process_checkout!: "
	if exist !repository_path! (
		call get_local_text error_path error path
		call ask_question "!error_path!"
		if "!result!"=="false" (
			call print_dashed_seperator
			goto:get_git_path
		) else (
			rmdir /s /q %repository_path%
			goto:git_checkout
		)
	) else (
		goto:git_checkout
	)
goto:eof

:git_checkout
	md "%repository_path%"
	set "repository_path=%repository_path%"

	call print_dashed_seperator
	set "git_app_path=%git_bash_path%\bin\git.exe"

	call get_config github_url
	"%git_app_path%" clone "!github_url!" "%repository_path%\coco"

	goto:git_configuration
goto:eof

:git_configuration
	call print_dashed_seperator

	call get_local_text github_config_intro github config intro
	echo !github_config_intro!

	call get_local_text github_config_info github config info
	echo !github_config_info!

	call print_dashed_seperator

	call get_local_text github_config_username github config username
	set /p "git_username=!github_config_username!"

	call get_local_text github_config_password github config password

	set /p "git_password=!github_config_password!"

	call print_dashed_seperator

	call get_local_text github_config_process github config process
	echo !github_config_process!

	set cur_dir=%CD%
	cd !repository_path!\coco

	"%git_app_path%" remote rm origin
	"%git_app_path%" remote add origin https://!git_username!:!git_password!@github.com/!git_username!/codecombat.git

	cd !cur_dir!

	goto:exit_git_setup
goto:eof

:exit_git_setup
	call print_dashed_seperator
goto:eof