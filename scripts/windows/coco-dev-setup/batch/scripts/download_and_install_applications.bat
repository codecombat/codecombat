call print_install_header
call print_dashed_seperator

call get_system_information
call print_dashed_seperator

if %system_info_os% == XP (
	call get_local_text install-system-xp
	echo !install_system_xp!
	call print_exit
)

call get_category ..\\config\\downloads.coco downloads downloads_count general-general general-%system_info_bit% %system_info_os%-%system_info_bit%

::for /l %%i in (1, 1, %downloads_count%) do (
::	echo %downloads[%%i]%
::)