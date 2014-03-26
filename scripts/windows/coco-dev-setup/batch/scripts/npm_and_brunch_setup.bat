call print_npm_and_brunch_header
call print_dashed_seperator

set work_directory=%CD%
set "coco_root=!repository_path!\coco"

call get_local_text npm-install
echo !npm_install!

cd !coco_root!
npm install -g bower brunch nodemon sendwithus
cd !work_directory!

call print_dashed_seperator
call get_local_text npm-binstall
echo !npm_binstall!

cd "!coco_root!"
bower install
cd "!work_directory!"

call print_dashed_seperator
call get_local_text npm-sass
echo !npm_sass!

cd "!coco_root!"
gem install sass
cd "!work_directory!"

call print_dashed_seperator
call get_local_text npm-npm
echo !npm_npm!

cd "!coco_root!"
npm install
cd "!work_directory!"

call print_dashed_seperator
call get_local_text npm-brnch
echo !npm_brnch!

cd "!coco_root!"
brunch w
cd "!work_directory!"

pause

call print_dashed_seperator
call get_local_text npm-mongodb
echo !npm_mongodb!

call print_dashed_seperator
call get_local_text npm-database
echo !npm_database!

pause

call print_dashed_seperator
call get_local_text npm-script
echo !npm_script!

pause

call print_dashed_seperator