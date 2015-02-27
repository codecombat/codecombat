config = require '../../server_config'
winston = require 'winston'
mongoose = require 'mongoose'
Grid = require 'gridfs-stream'
mongooseCache = require 'mongoose-cache'

global.testing = testing = '--unittest' in process.argv


module.exports.connect = () ->
  address = module.exports.generateMongoConnectionString()
  winston.info "Connecting to Mongo with connection string #{address}"

  mongoose.connect address
  mongoose.connection.once 'open', -> Grid.gfs = Grid(mongoose.connection.db, mongoose.mongo)

  mongooseCache.install(mongoose, {max: 200, maxAge: 1 * 60 * 1000, debug: false})

module.exports.generateMongoConnectionString = ->
  if not testing and config.mongo.mongoose_replica_string
    address = config.mongo.mongoose_replica_string
  else
    dbName = config.mongo.db
    dbName += '_unittest' if testing
    address = config.mongo.host + ':' + config.mongo.port
    if config.mongo.username and config.mongo.password
      address = config.mongo.username + ':' + config.mongo.password + '@' + address
    address = "mongodb://#{address}/#{dbName}"

  return address
