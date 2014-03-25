set "temp_directory=C:\\.coco\\"

if NOT exist "%temp_directory%" (
	md "%temp_directory%"
)

call get_local_text install-process-prefix
call get_local_text install-process-sufix

call ask_question "!install_process_prefix! %1 !install_process_sufix!"
call print_dashed_seperator

rmdir /s /q "%temp_directory%"