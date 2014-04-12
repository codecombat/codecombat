set "LFTP=%1-%language_id%.coco"
if not exist "%LFTP%" (
	echo printing %1.coco...
	call print_file %1.coco
) else (
	echo printing %LFTP%...
	call print_file %LFTP%
)