call print_npm_and_brunch_header
call print_dashed_seperator

set work_directory=%CD%

set "curl_app=..\utilities\curl.exe"
set "zu_app=..\utilities\7za.exe"

set coco_root=%repository_path%\coco
set coco_db=%repository_path%\cocodb

call nab_install_npm %coco_root%

call nab_install_bower %coco_root%

call nab_install_sass %coco_root%

call nab_install_npm_all %coco_root%

call nab_install_mongodb %coco_db%

call nab_automatic_script.bat %coco_root% %coco_db%

call print_dashed_seperator