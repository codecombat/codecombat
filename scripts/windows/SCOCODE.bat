set "mongo_db_location=C:\Users\Kevin\Documents\codecombat\db"
call npm update
call bower update
start cmd.exe cmd /c call nodemon -w server -w server_config.js
start cmd.exe cmd /c call brunch w^
  & mongod --setParameter textSearchEnabled=true^
    --dbpath %mongo_db_location%