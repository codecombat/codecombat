config = require '../../server_config'
winston = require 'winston'
mongoose = require 'mongoose'
Grid = require 'gridfs-stream'

testing = '--unittest' in process.argv


module.exports.connect = () ->
  if config.mongo.mongoose_replica_string
    address = config.mongo.mongoose_replica_string
    winston.info "Connecting to replica set: #{address}"
  else
    dbName = config.mongo.db
    dbName += '_unittest' if testing
    address = config.mongo.host + ":" + config.mongo.port
    if config.mongo.username and config.mongo.password
      address = config.mongo.username + ":" + config.mongo.password + "@" + address
  #    address = config.mongo.username + "@" + address # if connecting to production server
    address = "mongodb://#{address}/#{dbName}"
    winston.info "Connecting to standalone server #{address}"
  mongoose.connect address
  mongoose.connection.once 'open', ->
    Grid.gfs = Grid(mongoose.connection.db, mongoose.mongo)
