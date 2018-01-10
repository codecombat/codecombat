log = require 'winston'
mongoose = require 'mongoose'
plugins = require '../plugins/plugins'
utils = require '../lib/utils'
http = require 'http'
config = require '../../server_config'
jsonschema = require '../../app/schemas/models/analytics_log_event'

AnalyticsLogEventSchema = new mongoose.Schema({
  user: String #Actually a `mongoose.Schema.Types.ObjectId` but ...
  event: String
  properties: mongoose.Schema.Types.Mixed
}, {strict: false, versionKey: false})

AnalyticsLogEventSchema.index({event: 1, _id: -1})
AnalyticsLogEventSchema.index({event: 1, 'properties.level': 1})
AnalyticsLogEventSchema.index({event: 1, 'properties.levelID': 1})
AnalyticsLogEventSchema.index({user: 1, event: 1})
AnalyticsLogEventSchema.statics.jsonSchema = jsonschema

if global.testing
  AnalyticsLogEventSchema.pre('save', (next) ->
    # for testing
    if AnalyticsLogEvent.errorOnSave
      next(new Error('stap'))
    else
      next()
)

AnalyticsLogEventSchema.statics.logEvent = (user, event, properties={}) ->
  unless user?
    log.warn 'No user given to analytics logEvent.'
    return

  doc = new AnalyticsLogEvent
    user: user
    event: event
    properties: properties

  return doc.save()

unless config.proxy
  analyticsMongoose = mongoose.createConnection config.mongo.analytics_replica_string, (error) ->
    if error
      log.error "Couldn't connect to analytics", error
    else
      log.info "Connected to analytics mongo at #{config.mongo.analytics_replica_string}"

  module.exports = AnalyticsLogEvent = analyticsMongoose.model('analytics.log.event', AnalyticsLogEventSchema, config.mongo.analytics_collection)
