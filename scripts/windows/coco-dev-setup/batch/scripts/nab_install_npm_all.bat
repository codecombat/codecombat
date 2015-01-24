call print_dashed_seperator
call get_local_text npm_npm npm npm
echo %npm_npm%

cd /D %~1
start /wait cmd /c "echo %npm_npm% & npm install"
cd /D %work_directory%