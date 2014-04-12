echo Some feedback is sent in your system's language
echo but most feedback is sent and localised by us.
echo Here is a list of languages:
call print_dashed_seperator

call get_array ..\\localisation\\languages.coco languages language_count
for /l %%i in (1,1,%language_count%) do (
	call get_text !languages[%%i]! global_description global description
	echo   [%%i] !global_description!
)

goto:get_localisation_id

:get_localisation_id
	call print_dashed_seperator
	set /p "localisation_id=Enter the language ID of your preference and press <ENTER>: "
	goto:validation_check

:validation_check
	set "localisation_is_false="
	set /a local_id = %localisation_id%
	if !local_id! EQU 0 set localisation_is_false=1
	if !local_id! LSS 1 set localisation_is_false=1
	if !local_id! GTR !language_count! set localisation_is_false=1
	if defined localisation_is_false (
		echo The id you entered is invalid, please try again...
		goto:get_localisation_id
	) else (
		set language_id=!languages[%local_id%]!
		call print_dashed_seperator

		call get_local_text language_choosen language choosen
		echo !language_choosen!

		call get_local_text language_feedback language feedback
		echo !language_feedback!

		call print_seperator
	)