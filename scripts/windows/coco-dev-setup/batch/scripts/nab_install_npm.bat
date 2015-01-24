call get_local_text npm_install npm install
echo %npm_install%

cd /D %~1
start /wait cmd /c "echo %npm_install% & npm install -g bower brunch nodemon sendwithus"
cd /D %work_directory%