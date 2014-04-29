echo Some feedback is sent in your system's language
echo but most feedback is sent and localised by us.
echo Here is a list of languages:
call print_dashed_seperator

call get_array ..\\localization\\languages.coco languages language_count
for /l %%i in (1,1,%language_count%) do (
	call get_text !languages[%%i]! global_description global description
	echo   [%%i] !global_description!
)

goto:get_localization_id

:get_localization_id
	call print_dashed_seperator
	set /p "localization_id=Enter the language ID of your preference and press <ENTER>: "
	goto:validation_check

:validation_check
	set "localization_is_false="
	set /a local_id = %localization_id%
	if !local_id! EQU 0 set localization_is_false=1
	if !local_id! LSS 1 set localization_is_false=1
	if !local_id! GTR !language_count! set localization_is_false=1
	if defined localization_is_false (
		echo The id you entered is invalid, please try again...
		goto:get_localization_id
	) else (
		set language_id=!languages[%local_id%]!
		call print_dashed_seperator

		call get_local_text language_choosen language choosen
		echo !language_choosen!

		call get_local_text language_feedback language feedback
		echo !language_feedback!

		call print_seperator
	)