<<<<<<< HEAD
echo In order to continue the installation of the developers environment
echo you will have to read and agree with the following license:
call print_dashed_seperator

call print_license
call print_dashed_seperator

call ask_question "Have you read the license and do you agree with it?"
call print_dashed_seperator

if "%result%"=="false" (
	echo This setup can't happen without an agreement.
	echo Installation and Setup of the CodeCombat environment is cancelled.
	call print_exit
=======
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
>>>>>>> 072729acc34123c42250d361955438cfd8c210d7
)