log = require 'winston'
mongoose = require 'mongoose'
plugins = require '../plugins/plugins'
utils = require '../lib/utils'

AnalyticsLogEventSchema = new mongoose.Schema({
  u: mongoose.Schema.Types.ObjectId
  e: Number  # event analytics.string ID
  p: mongoose.Schema.Types.Mixed

  # TODO: Remove these legacy properties after we stop querying for them (probably 30 days, ~2/16/15)
  user: mongoose.Schema.Types.ObjectId
  event: String
  properties: mongoose.Schema.Types.Mixed
}, {strict: false})

AnalyticsLogEventSchema.index({event: 1, _id: 1})

AnalyticsLogEventSchema.statics.logEvent = (user, event, properties={}) ->
  # Replaces some keys and values with analytics string IDs to reduce the size of events
  unless user?
    log.warn 'No user given to analytics logEvent.'
    return

  # TODO: Replace methods inefficient, watch logEvent server perf.

  replaceKeys = (slimProperties, callback) ->
    # Replace all slimProperties key values with string IDs
    for key, value of slimProperties
      if isNaN(parseInt(key))
        utils.getAnalyticsStringID key, (stringID) ->
          if stringID > 0
            slimProperties[stringID] = value
            delete slimProperties[key]
            replaceKeys slimProperties, callback
          else
            callback()
        return
    callback()

  replaceProperties = (slimProperties, callback) ->
    # Replace select slimProperties property values with string IDs
    for key, value of slimProperties
      if key in ['level', 'levelID', 'label', 'style'] and isNaN(parseInt(value))
        if key is 'levelID'
          key = 'level'
          slimProperties['level'] = _.cloneDeep slimProperties['levelID']
          delete slimProperties['levelID']
        utils.getAnalyticsStringID value, (stringID) ->
          if stringID > 0
            slimProperties[key] = stringID
            replaceProperties slimProperties, callback
          else
            callback()
        return
    callback()

  saveDoc = (eventID, slimProperties) ->
    replaceProperties slimProperties, ->
      replaceKeys slimProperties, ->
        doc = new AnalyticsLogEvent
          u: user
          e: eventID
          p: slimProperties
          # TODO: Remove these legacy properties after we stop querying for them, sometime after ~3/10/15
          user: user
          event: event
          properties: properties
        doc.save()

  utils.getAnalyticsStringID event, (eventID) ->
    if eventID > 0
      slimProperties = _.cloneDeep properties
      properties.ls = mongoose.Types.ObjectId properties.ls if properties.ls
      slimProperties.ls = mongoose.Types.ObjectId slimProperties.ls if slimProperties.ls

      # Event-specific updates
      if event is 'Saw Victory'
        delete slimProperties.level
      if event is 'Heard Sprite' and slimProperties.message?
        utils.getAnalyticsStringID slimProperties.message, (stringID) ->
          slimProperties.message = stringID if stringID > 0
          saveDoc eventID, slimProperties
        return

      saveDoc eventID, slimProperties
    else
      log.warn "Unable to get analytics string ID for " + event

module.exports = AnalyticsLogEvent = mongoose.model('analytics.log.event', AnalyticsLogEventSchema)
