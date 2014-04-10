set "cache=..\\config\\cache.coco"

echo ^<?xml version="1.0" encoding="ISO-8859-1" ?^>>%cache%

echo ^<variables^>>>%cache%

echo 	^<language_id^>%language_id%^</language_id^>>>%cache%
echo 	^<repository_path^>%repository_path%^</repository_path^>>>%cache%

echo ^</variables^>>>%cache%