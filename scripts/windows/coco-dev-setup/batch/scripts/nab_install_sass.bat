call print_dashed_seperator
call get_local_text npm_sass npm sass
echo %npm_sass%

cd /D %~1
start /wait cmd /c "echo %npm_sass% & gem install sass"
cd /D %work_directory%