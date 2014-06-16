config = require 'server_config'

#TODO: Could kill current coco server here.

requrie('')

npm = require "npm"
npm.load npm.config, (err) ->
  if err
    console.log "Loading npm failed:",err
    return


  npm.commands.install ["ffi"], (er, data) ->


    # log the error or data
  npm.on "log", (message) ->

    # log the progress of the installation
    console.log message
    return


if '--clean' in process.argv
  # TODO: What if mongo is not running?
  require('server\commons\databse').connect()
  mongoose = require 'mongoose'
  mongoose.connection.db.dropDatabase()

# TODO: Could advice to start SCOCODE.bat et al. here