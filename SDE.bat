set "mongo_d_location=E:\GameDevelopment\db"
start cmd.exe cmd /c call nodemon -w server -w server_config.js
start cmd.exe cmd /c call brunch w^
  & mongod --setParameter textSearchEnabled=true^
    --dbpath %mongo_d_location%