mongoose = require 'mongoose'
EarnedAchievement = require '../models/EarnedAchievement'
LocalMongo = require '../../app/lib/LocalMongo'
util = require '../../app/core/utils'
log = require 'winston'

# Warning: To ensure proper functioning one must always `find` documents before saving them.
# Otherwise the schema's `post init` won't be triggered and the plugin can't keep track of changes
# TODO if this is still a common scenario I could implement a database hit after all, but only
# on the condition that it's necessary and still not too frequent in occurrence
AchievablePlugin = (schema, options) ->
  User = require '../models/User'  # Avoid mutual inclusion cycles
  Achievement = require '../models/Achievement'

  # Keep track the document before it's saved
  schema.post 'init', (doc) ->
    unless doc.unchangedCopy
      doc.unchangedCopy = doc.toObject()

  # Check if an achievement has been earned
  schema.post 'save', (doc) ->
    schema.statics.createNewEarnedAchievements doc

  schema.statics.createNewEarnedAchievements = (doc, unchangedCopy) ->
    unchangedCopy ?= doc.unchangedCopy
    isNew = not doc.isInit('_id') or not unchangedCopy

    if doc.isInit('_id') and not unchangedCopy
      log.warn 'document was already initialized but did not go through `init` and is therefore treated as new while it might not be'

    category = doc.constructor.collection.name
    loadedAchievements = Achievement.getLoadedAchievements()

    if category of loadedAchievements
      #log.debug 'about to save ' + category + ', number of achievements is ' + loadedAchievements[category].length
      docObj = doc.toObject()
      for achievement in loadedAchievements[category]
        do (achievement) ->
          query = achievement.get('query')
          return log.error("Empty achievement query for #{achievement.get('name')}.") if _.isEmpty query
          isRepeatable = achievement.get('proportionalTo')?
          alreadyAchieved = if isNew then false else LocalMongo.matchesQuery unchangedCopy, query
          newlyAchieved = LocalMongo.matchesQuery(docObj, query)
          return unless newlyAchieved and (not alreadyAchieved or isRepeatable)
          #log.info "Making an achievement: #{achievement.get('name')} #{achievement.get('_id')} for doc: #{doc.get('name')} #{doc.get('_id')}"
          EarnedAchievement.createForAchievement(achievement, doc, unchangedCopy)

module.exports = AchievablePlugin
