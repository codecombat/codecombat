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
)