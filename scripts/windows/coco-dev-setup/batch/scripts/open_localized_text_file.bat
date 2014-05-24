set "LFTP=%1-%language_id%.coco"
if not exist "%LFTP%" (
	call open_text_file %1.coco
) else (
	call open_text_file %LFTP%
)