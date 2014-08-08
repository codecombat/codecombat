mongoose = require 'mongoose'
EarnedAchievement = require '../achievements/EarnedAchievement'
LocalMongo = require '../../app/lib/LocalMongo'
util = require '../../app/lib/utils'
log = require 'winston'

# Warning: To ensure proper functioning one must always `find` documents before saving them.
# Otherwise the schema's `post init` won't be triggered and the plugin can't keep track of changes
# TODO if this is still a common scenario I could implement a database hit after all, but only
# on the condition that it's necessary and still not too frequent in occurrence
AchievablePlugin = (schema, options) ->
  User = require '../users/User'  # Avoid mutual inclusion cycles
  Achievement = require '../achievements/Achievement'

  before = {}

  # Keep track the document before it's saved
  schema.post 'init', (doc) ->
    before[doc.id] = doc.toObject()
    # TODO check out how many objects go unreleased

  # Check if an achievement has been earned
  schema.post 'save', (doc) ->
    isNew = not doc.isInit('_id') or not (doc.id of before)
    originalDocObj = before[doc.id] unless isNew

    if doc.isInit('_id') and not doc.id of before
      log.warn 'document was already initialized but did not go through `init` and is therefore treated as new while it might not be'

    category = doc.constructor.collection.name
    loadedAchievements = Achievement.getLoadedAchievements()
    #log.debug 'about to save ' + category + ', number of achievements is ' + Object.keys(loadedAchievements).length

    if category of loadedAchievements
      docObj = doc.toObject()
      for achievement in loadedAchievements[category]
        query = achievement.get('query')
        isRepeatable = achievement.get('proportionalTo')?
        alreadyAchieved = if isNew then false else LocalMongo.matchesQuery originalDocObj, query
        newlyAchieved = LocalMongo.matchesQuery(docObj, query)
        #log.debug 'isRepeatable: ' + isRepeatable
        #log.debug 'alreadyAchieved: ' +  alreadyAchieved
        #log.debug 'newlyAchieved: ' + newlyAchieved

        userObjectID = doc.get(achievement.get('userField'))
        userID = if _.isObject userObjectID then userObjectID.toHexString() else userObjectID # Standardize! Use strings, not ObjectId's

        if newlyAchieved and (not alreadyAchieved or isRepeatable)
          earned =
            user: userID
            achievement: achievement._id.toHexString()
            achievementName: achievement.get 'name'

          worth = achievement.get('worth')
          earnedPoints = 0
          wrapUp = ->
            # Update user's experience points
            User.update {_id: userID}, {$inc: {points: earnedPoints}}, {}, (err, count) ->
              log.error err if err?

          if isRepeatable
            #log.debug 'Upserting repeatable achievement called \'' + (achievement.get 'name') + '\' for ' + userID
            proportionalTo = achievement.get 'proportionalTo'
            originalAmount = if originalDocObj then util.getByPath(originalDocObj, proportionalTo) or 0 else 0
            newAmount = docObj[proportionalTo]

            if originalAmount isnt newAmount
              expFunction = achievement.getExpFunction()
              earned.notified = false
              earned.achievedAmount = newAmount
              earned.earnedPoints = (expFunction(newAmount) - expFunction(originalAmount)) * worth
              earned.previouslyAchievedAmount = originalAmount
              EarnedAchievement.update {achievement: earned.achievement, user: earned.user}, earned, {upsert: true}, (err) ->
                return log.debug err if err?

              earnedPoints = earned.earnedPoints
              #log.debug earnedPoints
              wrapUp()

          else # not alreadyAchieved
            #log.debug 'Creating a new earned achievement called \'' + (achievement.get 'name') + '\' for ' + userID
            earned.earnedPoints = worth
            (new EarnedAchievement(earned)).save (err, doc) ->
              return log.error err if err?
              earnedPoints = worth
              wrapUp()

    delete before[doc.id] if doc.id of before

module.exports = AchievablePlugin
