@echo off
setlocal EnableDelayedExpansion

call read_cache

call configuration_cmd

call npm_and_brunch_setup

call print_finished_header
call print_dashed_seperator

call get_local_text end_succesfull end succesfull
call get_local_text end_thankyou end thankyou
echo %end_succesfull%
echo %end_thankyou%

call print_dashed_seperator

call get_local_text start_s1 start s1
call get_local_text start_s2 start s2
call get_local_text start_s3 start s3
call get_local_text start_s4 start s4
call get_local_text start_s5 start s5
call get_local_text start_s6 start s6

echo !start_s1!
echo !start_s2!
echo.
echo !start_s3! '!repository_path!\coco\SCOCODE.bat'
echo !start_s4!
echo !start_s5!
echo.
echo !start_s6!

call print_dashed_seperator

call get_local_text end_readme end readme
call ask_question "!end_readme!"

if "%result%"=="true" (
	call open_readme
)

exit

endlocal