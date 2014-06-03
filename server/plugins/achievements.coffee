mongoose = require('mongoose')
Achievement = require('../achievements/Achievement')
EarnedAchievement = require '../achievements/EarnedAchievement'
User = require '../users/User'
LocalMongo = require '../../app/lib/LocalMongo'
util = require '../../app/lib/utils'
log = require 'winston'

achievements = {}

loadAchievements = ->
  achievements = {}
  query = Achievement.find({})
  query.exec (err, docs) ->
    _.each docs, (achievement) ->
      category = achievement.get 'collection'
      achievements[category] = [] unless category of achievements
      achievements[category].push achievement
loadAchievements()

module.exports = AchievablePlugin = (schema, options) ->
  checkForAchievement = (doc) ->
    collectionName = doc.constructor.modelName

  before = {}

  schema.post 'init', (doc) ->
    before[doc.id] = doc.toObject()

  schema.post 'save', (doc) ->
    isNew = not doc.isInit('_id')
    originalDocObj = before[doc.id] unless isNew

    category = doc.constructor.modelName

    if category of achievements
      docObj = doc.toObject()
      for achievement in achievements[category]
        query = achievement.get('query')
        isRepeatable = achievement.get('proportionalTo')?
        alreadyAchieved = if isNew then false else LocalMongo.matchesQuery originalDocObj, query
        newlyAchieved = LocalMongo.matchesQuery(docObj, query)
        log.debug 'isRepeatable: ' + isRepeatable
        log.debug 'alreadyAchieved: ' +  alreadyAchieved
        log.debug 'newlyAchieved: ' + newlyAchieved

        userObjectID = doc.get(achievement.get('userField'))
        userID = if _.isObject userObjectID then userObjectID.toHexString() else userObjectID # Standardize! Use strings, not ObjectId's

        if newlyAchieved and (not alreadyAchieved or isRepeatable)
          earned = {
            user: userID
            achievement: achievement._id.toHexString()
            achievementName: achievement.get 'name'
          }
          earnedPoints = 0
          wrapUp = ->
            # Update user's experience points
            User.update({_id: userID}, {$inc: {points: earnedPoints}}, {}, (err, count) ->
              console.error err if err?
            )

          if isRepeatable
            log.debug 'Upserting repeatable achievement called \'' + (achievement.get 'name') + '\' for ' + userID
            proportionalTo = achievement.get 'proportionalTo'
            originalAmount = util.getByPath(originalDocObj, proportionalTo) or 0
            newAmount = docObj[proportionalTo]

            if originalAmount isnt newAmount
              earned.notified = false
              earned.achievedAmount = newAmount
              earned.changed = Date.now()
              EarnedAchievement.findOneAndUpdate({achievement:earned.achievement, user:earned.user}, earned, upsert:true, (err, docs) ->
                  return log.debug err if err?
              )

              earnedPoints = achievement.get('worth') * (newAmount - originalAmount)
              wrapUp()

          else # not alreadyAchieved
            log.debug 'Creating a new earned achievement called \'' + (achievement.get 'name') + '\' for ' + userID
            (new EarnedAchievement(earned)).save (err, doc) ->
              return log.debug err if err?

              earnedPoints = achievement.get('worth')
              wrapUp()

    delete before[doc.id] unless isNew # This assumes everything we patch has a _id
    return
