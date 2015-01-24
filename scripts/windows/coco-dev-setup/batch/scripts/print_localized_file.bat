set "LFTP=%1-%language_id%.coco"
if not exist "%LFTP%" (
	call print_file %1.coco
) else (
	call print_file %LFTP%
)