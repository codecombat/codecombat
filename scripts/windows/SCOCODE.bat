set "mongo_db_location=MONGO_DB_PATH_HERE"
start cmd.exe cmd /c call nodemon -w server -w server_config.js
start cmd.exe cmd /c call brunch w^
  & mongod --setParameter textSearchEnabled=true^
    --dbpath %mongo_db_location%