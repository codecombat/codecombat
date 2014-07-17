call get_local_text license_s1 license s1
echo !license_s1!

call get_local_text license_s2 license s2
echo !license_s2!

call print_dashed_seperator

call print_license
call print_dashed_seperator

call get_local_text license_q1 license q1
call ask_question "%license_q1%"

call print_dashed_seperator

if "%result%"=="false" (
	call get_local_text license_a1 license a1
	echo !license_a1!

	call get_local_text license_a2 license a2
	echo !license_a2!

	echo.

	call print_exit
)