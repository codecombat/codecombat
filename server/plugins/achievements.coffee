mongoose = require 'mongoose'
EarnedAchievement = require '../achievements/EarnedAchievement'
LocalMongo = require '../../app/lib/LocalMongo'
util = require '../../app/core/utils'
log = require 'winston'

# Warning: To ensure proper functioning one must always `find` documents before saving them.
# Otherwise the schema's `post init` won't be triggered and the plugin can't keep track of changes
# TODO if this is still a common scenario I could implement a database hit after all, but only
# on the condition that it's necessary and still not too frequent in occurrence
AchievablePlugin = (schema, options) ->
  User = require '../users/User'  # Avoid mutual inclusion cycles
  Achievement = require '../achievements/Achievement'

  # Keep track the document before it's saved
  schema.post 'init', (doc) ->
    doc.unchangedCopy = doc.toObject()

  # Check if an achievement has been earned
  schema.post 'save', (doc) ->
    isNew = not doc.isInit('_id') or not doc.unchangedCopy

    if doc.isInit('_id') and not doc.unchangedCopy
      log.warn 'document was already initialized but did not go through `init` and is therefore treated as new while it might not be'

    category = doc.constructor.collection.name
    loadedAchievements = Achievement.getLoadedAchievements()
    #log.debug 'about to save ' + category + ', number of achievements is ' + Object.keys(loadedAchievements).length

    if category of loadedAchievements
      docObj = doc.toObject()
      for achievement in loadedAchievements[category]
        do (achievement) ->
          query = achievement.get('query')
          return log.warn("Empty achievement query for #{achievement.get('name')}.") if _.isEmpty query
          isRepeatable = achievement.get('proportionalTo')?
          alreadyAchieved = if isNew then false else LocalMongo.matchesQuery doc.unchangedCopy, query
          newlyAchieved = LocalMongo.matchesQuery(docObj, query)
          return unless newlyAchieved and (not alreadyAchieved or isRepeatable)
          EarnedAchievement.createForAchievement(achievement, doc, doc.unchangedCopy)

module.exports = AchievablePlugin
