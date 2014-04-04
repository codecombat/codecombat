call print_npm_and_brunch_header
call print_dashed_seperator

set work_directory=%CD%

set "curl_app=..\utilities\curl.exe"
set "zu_app=..\utilities\7za.exe"
set "keystuff=..\utilities\keystuff.exe"

set "coco_root=!repository_path!\coco"

goto:automatic_script

call get_local_text npm-install
echo !npm_install!

cd !coco_root!
start /wait cmd /c "echo !npm_install! & npm install -g bower brunch nodemon sendwithus"
cd !work_directory!

call print_dashed_seperator
call get_local_text npm-binstall
echo !npm_binstall!

cd "!coco_root!"
start /wait cmd /c "echo !npm_binstall! & bower install"
cd "!work_directory!"

call print_dashed_seperator
call get_local_text npm-sass
echo !npm_sass!

cd "!coco_root!"
start /wait cmd /c "echo !npm_sass! & gem install sass"
cd "!work_directory!"

call print_dashed_seperator
call get_local_text npm-npm
echo !npm_npm!

cd "!coco_root!"
start /wait cmd /c "echo !npm_npm! & npm install"
cd "!work_directory!"

:: --- MONGODB

:mongodb
call print_dashed_seperator
call get_local_text npm-mongodb
echo !npm_mongodb!

set "mdb_directory=!repository_path!\cocodb"

if exist mdb_directory (
	rmdir /s /q "!mdb_directory!"
)

md !mdb_directory!

call print_dashed_seperator
call get_local_text npm-db
echo !npm_db!

call get_config database_backup

cd !mdb_directory!

start cmd /c "%work_directory%\%keystuff% Alt-Tab && mongod --setParameter textSearchEnabled=true --dbpath !mdb_directory!"

%curl_app% -k !database_backup! -o dump.tar.gz

start /wait cmd /c "%work_directory%\%keystuff% Alt-Tab && %zu_app% e dump.tar.gz && del dump.tar.gz && %zu_app% x dump.tar && del dump.tar"

start /wait cmd /c "mongorestore dump"

rmdir /s /q db

:: --- AUTOMATIC SCRIPT

::automatic_script
call print_dashed_seperator
call get_local_text npm-script
echo !npm_script!

:: --- END

call print_dashed_seperator

pause