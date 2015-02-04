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

AnalyticsLogEventSchema.statics.logEvent = (user, event, properties) ->
  unless user?
    log.warn 'No user given to analytics logEvent.'
    return

  saveDoc = (eventID, slimProperties) ->
    doc = new AnalyticsLogEvent
      u: user
      e: eventID
      p: slimProperties
      # TODO: Remove these legacy properties after we stop querying for them (probably 30 days, ~2/16/15)
      user: user
      event: event
      properties: properties
    doc.save()

  utils.getAnalyticsStringID event, (eventID) ->
    if eventID > 0
      # TODO: properties slimming is pretty ugly
      slimProperties = _.cloneDeep properties
      if event in ['Clicked Level', 'Show problem alert', 'Started Level', 'Saw Victory', 'Problem alert help clicked', 'Spell palette help clicked']
        delete slimProperties.level if event is 'Saw Victory'
        properties.ls = mongoose.Types.ObjectId properties.ls if properties.ls
        slimProperties.ls = mongoose.Types.ObjectId slimProperties.ls if slimProperties.ls
        if slimProperties.levelID?
          # levelID: string => l: string ID
          utils.getAnalyticsStringID slimProperties.levelID, (levelStringID) ->
            if levelStringID > 0
              delete slimProperties.levelID
              slimProperties.l = levelStringID
            saveDoc eventID, slimProperties
          return
      else if event in ['Script Started', 'Script Ended']
        properties.ls = mongoose.Types.ObjectId properties.ls if properties.ls
        slimProperties.ls = mongoose.Types.ObjectId slimProperties.ls if slimProperties.ls
        if slimProperties.levelID? and slimProperties.label?
          # levelID: string => l: string ID
          # label: string => lb: string ID
          utils.getAnalyticsStringID slimProperties.levelID, (levelStringID) ->
            if levelStringID > 0
              delete slimProperties.levelID
              slimProperties.l = levelStringID
            utils.getAnalyticsStringID slimProperties.label, (labelStringID) ->
              if labelStringID > 0
                delete slimProperties.label
                slimProperties.lb = labelStringID
              saveDoc eventID, slimProperties
          return
      else if event is 'Heard Sprite'
        properties.ls = mongoose.Types.ObjectId properties.ls if properties.ls
        slimProperties.ls = mongoose.Types.ObjectId slimProperties.ls if slimProperties.ls
        if slimProperties.message?
          # message: string => m: string ID
          utils.getAnalyticsStringID slimProperties.message, (messageStringID) ->
            if messageStringID > 0
              delete slimProperties.message
              slimProperties.m = messageStringID
            saveDoc eventID, slimProperties
          return
      else if event in ['Start help video', 'Finish help video']
        properties.ls = mongoose.Types.ObjectId properties.ls if properties.ls
        slimProperties.ls = mongoose.Types.ObjectId slimProperties.ls if slimProperties.ls
        if slimProperties.level and slimProperties.style?
          # level: string => l: string ID
          # style: string => s: string ID
          utils.getAnalyticsStringID slimProperties.level, (levelStringID) ->
            if levelStringID > 0
              delete slimProperties.level
              slimProperties.l = levelStringID
            utils.getAnalyticsStringID slimProperties.style, (styleStringID) ->
              if styleStringID > 0
                delete slimProperties.style
                slimProperties.s = styleStringID
              saveDoc eventID, slimProperties
          return
      else if event is 'Show subscription modal'
        delete properties.category
        delete slimProperties.category
        if slimProperties.label?
          # label: string => lb: string ID
          utils.getAnalyticsStringID slimProperties.label, (labelStringID) ->
            if labelStringID > 0
              delete slimProperties.label
              slimProperties.lb = labelStringID
            if slimProperties.level?
              # level: string => l: string ID
              utils.getAnalyticsStringID slimProperties.level, (levelStringID) ->
                if levelStringID > 0
                  delete slimProperties.level
                  slimProperties.l = levelStringID
                saveDoc eventID, slimProperties
              return
            saveDoc eventID, slimProperties
          return
      saveDoc eventID, slimProperties
    else
      log.warn "Unable to get analytics string ID for " + event

module.exports = AnalyticsLogEvent = mongoose.model('analytics.log.event', AnalyticsLogEventSchema)
