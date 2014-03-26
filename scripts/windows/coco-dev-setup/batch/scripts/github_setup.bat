call print_github_header
call print_dashed_seperator

call get_local_text github-intro-opensource
call get_local_text github-intro-online
call get_local_text github-intro-manual
call get_local_text github-intro-norec

echo !github_intro_opensource!
echo !github_intro_online!
echo !github_intro_manual!
echo !github_intro_norec!

call print_dashed_seperator

call get_local_text github-skip-question
call ask_question "!github_skip_question!"
call print_dashed_seperator

if "%result%"=="true" (
	call get_local_text github-skip-consequence
	echo !github_skip_consequence!

	call get_local_text github-skip-donotclose
	echo !github_skip_donotclose!

	call get_local_text github-skip-wait
	set /p "github_skip_wait=!github_skip_wait!"

	call print_dashed_seperator

	call get_local_text github-process-path
	call get_path_safe "!github_process_path!"
	set "repository_path=!tmp_safe_path!"

	goto:exit_git_setup
)

:exit_git_setup
	call print_dashed_seperator