log = require 'winston'
mongoose = require 'mongoose'
plugins = require '../plugins/plugins'
utils = require '../lib/utils'
http = require 'http'
config = require '../../server_config'

AnalyticsLogEventSchema = new mongoose.Schema({
  user: String #Actually a `mongoose.Schema.Types.ObjectId` but ...
  event: String
  properties: mongoose.Schema.Types.Mixed
}, {strict: false, versionKey: false})

AnalyticsLogEventSchema.index({event: 1, _id: -1})
AnalyticsLogEventSchema.index({event: 1, 'properties.level': 1})
AnalyticsLogEventSchema.index({event: 1, 'properties.levelID': 1})
AnalyticsLogEventSchema.index({user: 1, event: 1})

AnalyticsLogEventSchema.statics.logEvent = (user, event, properties={}) ->
  unless user?
    log.warn 'No user given to analytics logEvent.'
    return

  doc = new AnalyticsLogEvent
    user: user
    event: event
    properties: properties

  doc.save()

unless config.proxy
  analyticsMongoose = mongoose.createConnection()
  analyticsMongoose.open "mongodb://#{config.mongo.analytics_host}:#{config.mongo.analytics_port}/#{config.mongo.analytics_db}", (error) ->
    log.warn "Couldnt connect to analytics", error
  
  module.exports = AnalyticsLogEvent = analyticsMongoose.model('analytics.log.event', AnalyticsLogEventSchema, config.mongo.analytics_collection)
