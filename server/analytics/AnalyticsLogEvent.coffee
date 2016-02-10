log = require 'winston'
mongoose = require 'mongoose'
plugins = require '../plugins/plugins'
utils = require '../lib/utils'
http = require 'http'
config = require '../../server_config'

AnalyticsLogEventSchema = new mongoose.Schema({
  u: mongoose.Schema.Types.ObjectId
  e: Number  # event analytics.string ID
  p: mongoose.Schema.Types.Mixed

  # TODO: Remove these legacy properties after we stop querying for them (probably 30 days, ~2/16/15)
  user: mongoose.Schema.Types.ObjectId
  event: String
  properties: mongoose.Schema.Types.Mixed
}, {strict: false})

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
  if config.isProduction and not config.unittest
    docString = JSON.stringify doc
    headers =
      "Content-Type":'application/json'
      "Content-Length": docString.length

    options =
      host: 'analytics.codecombat.com'
      port: 80
      path: '/analytics'
      method: 'POST'
      headers: headers
    req = http.request options, (res) ->
    req.on 'error', (e) -> log.warn e
    req.write(docString)
    req.end()
  else
    doc.save()

module.exports = AnalyticsLogEvent = mongoose.model('analytics.log.event', AnalyticsLogEventSchema)
