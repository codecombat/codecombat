config = require '../../server_config'
winston = require 'winston'
mongoose = require 'mongoose'
Grid = require 'gridfs-stream'
mongooseCache = require 'mongoose-cache'

module.exports.connect = () ->
  address = module.exports.generateMongoConnectionString()
  winston.info "Connecting to Mongo with connection string #{address}"

  mongoose.connect address
  mongoose.connection.once 'open', -> Grid.gfs = Grid(mongoose.connection.db, mongoose.mongo)

  # Hack around Mongoose not exporting Aggregate so that we can patch its exec, too
  # https://github.com/LearnBoost/mongoose/issues/1910
  Level = require '../levels/Level'
  Aggregate = Level.aggregate().constructor
  maxAge = (Math.random() * 10 + 10) * 60 * 1000  # Randomize so that each server doesn't refresh cache from db at same times
  mongooseCache.install(mongoose, {max: 1000, maxAge: maxAge, debug: false}, Aggregate)

module.exports.generateMongoConnectionString = ->
  if not global.testing and config.tokyo
    address = config.mongo.mongoose_tokyo_replica_string
  else if not global.testing and config.saoPaulo
    address = config.mongo.mongoose_saoPaulo_replica_string
  else if not global.testing and config.mongo.mongoose_replica_string
    address = config.mongo.mongoose_replica_string
  else
    dbName = config.mongo.db
    dbName += '_unittest' if global.testing
    address = config.mongo.host + ':' + config.mongo.port
    if config.mongo.username and config.mongo.password
      address = config.mongo.username + ':' + config.mongo.password + '@' + address
    address = "mongodb://#{address}/#{dbName}"

  return address
