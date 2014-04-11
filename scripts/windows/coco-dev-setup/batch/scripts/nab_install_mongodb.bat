call print_dashed_seperator
call get_local_text npm_mongodb npm mongodb
echo %npm_mongodb%

if exist %~1 (
	rmdir /s /q %~1
)

md %~1

call print_dashed_seperator
call get_local_text npm_db npm db
echo %npm_db%

call get_config database_backup

call get_local_text npm_close npm close

cd /D %~1

start cmd /c "TITLE MongoDB - %npm_close% & mongod --setParameter textSearchEnabled=true --dbpath %~1"

start /wait cmd.exe /c "TITLE downloading database backup... && %work_directory%\%curl_app% -k -m 10800 --retry 100 -o dump.tar.gz %database_backup%"

start /wait cmd /c "%work_directory%\%zu_app% e dump.tar.gz && del dump.tar.gz && %work_directory%\%zu_app% x dump.tar && del dump.tar"

start /wait cmd /c "mongorestore dump"

rmdir /s /q dump

call %work_directory%\print_dashed_seperator

taskkill /F /fi "IMAGENAME eq mongod.exe"

del /F %~1\mongod.lock

cd /D %work_directory%