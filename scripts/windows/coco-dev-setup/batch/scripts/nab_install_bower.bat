call print_dashed_seperator
call get_local_text npm_binstall npm binstall
echo %npm_binstall%

cd /D %~1
start /wait cmd /c "echo %npm_binstall% & bower cache clean & bower install"
cd /D %work_directory%