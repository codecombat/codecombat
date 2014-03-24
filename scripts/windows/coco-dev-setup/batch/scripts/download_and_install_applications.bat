call print_install_header
call print_dashed_seperator

call get_system_information
call print_dashed_seperator

if %system_info_os% == XP (
	call get_local_text install-system-xp
	echo !install_system_xp!
	call print_exit
)

call get_category ..\\config\\downloads.coco downloads downloads_count download_names download_names_count general-general general-%system_info_bit% %system_info_os%-%system_info_bit%

call get_local_text install-intro-1
call get_local_text install-intro-2
call get_local_text install-intro-3
call get_local_text install-intro-4

echo !install_intro_1!
echo !install_intro_2!
echo !install_intro_3!
echo !install_intro_4!

call print_dashed_seperator

set "temp_directory = C:\\.tmp\\coco"

call download_and_install_app

::for /l %%i in (1, 1, %downloads_count%) do (
::	echo %downloads[%%i]%
::)