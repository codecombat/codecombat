call print_install_header
call print_dashed_seperator

call get_local_text install-process-sks
echo !install_process_sks!

call get_local_text install-process-skq
call ask_question "!install_process_skq!"

call print_dashed_seperator

if "%result%"=="true" (
	call get_local_text install-process-skc
	echo !install_process_skc!
	call print_dashed_seperator
	goto:exit_setup
)

call get_system_information
call print_dashed_seperator

if %system_info_os% == XP (
	call get_local_text install-system-xp
	echo !install_system_xp!
	call print_exit
)

call get_category ..\\config\\downloads.coco downloads download_names downloads_count general-general general-%system_info_bit% %system_info_os%-%system_info_bit%

call get_local_text install-process-1
call get_local_text install-process-2
call get_local_text install-process-3
call get_local_text install-process-4

echo !install_process_1!
echo !install_process_2!
echo !install_process_3!
echo !install_process_4!

call print_dashed_seperator

for /l %%i in (1, 1, !downloads_count!) do (
	call download_and_install_app !download_names[%%i]! !downloads[%%i]!
)

goto:exit_setup

:exit_setup