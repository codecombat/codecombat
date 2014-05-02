call print_install_header
call print_dashed_seperator

call get_local_text install_process_sks install process sks
echo !install_process_sks!

call get_local_text install_process_skq install process skq
call ask_question "!install_process_skq!"

call print_dashed_seperator

if "%result%"=="true" (
	call get_local_text install_process_skc install process skc
	echo !install_process_skc!
	call print_dashed_seperator
	goto:exit_setup
)

call get_system_information
call print_dashed_seperator

if %system_info_os% == XP (
	call get_local_text install_system_xp install system xp
	echo !install_system_xp!
	call print_exit
)

call get_variables ..\\config\\downloads.coco downloads download_names downloads_count 0 general general
call get_variables ..\\config\\downloads.coco downloads download_names downloads_count 2 %system_info_os% b%system_info_bit%
call get_variables ..\\config\\downloads.coco downloads download_names downloads_count 3 general b%system_info_bit%

call get_local_text install_process_s1 install process s1
call get_local_text install_process_s2 install process s2
call get_local_text install_process_s3 install process s3
call get_local_text install_process_s4 install process s4
call get_local_text install_process_winpath install process winpath

echo !install_process_s1!
echo !install_process_s2!
echo !install_process_s3!
echo.
echo !install_process_s4!
echo.
echo !install_process_winpath!

call print_dashed_seperator

for /l %%i in (1, 1, !downloads_count!) do (
	call download_and_install_app !download_names[%%i]! !downloads[%%i]!
)

goto:exit_setup

:exit_setup