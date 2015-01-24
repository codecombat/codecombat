call print_dashed_seperator
call get_local_text npm_script npm script
echo %npm_script%

echo start cmd.exe cmd /c "TITLE CodeCombat.com - mongodb database & mongod --setParameter textSearchEnabled=true --dbpath %~2">%~1\SCOCODE.bat
echo start cmd.exe cmd /c "TITLE CodeCombat.com - nodemon server & nodemon index.js">>%~1\SCOCODE.bat
echo start cmd.exe cmd /c "TITLE CodeCombat.com - brunch - live compiler & brunch w">>%~1\SCOCODE.bat