mongoose = require 'mongoose'
EarnedAchievement = require '../achievements/EarnedAchievement'
LocalMongo = require '../../app/lib/LocalMongo'
util = require '../../app/lib/utils'
log = require 'winston'

achievements = {}

module.exports = AchievablePlugin = (schema, options) ->
  User = require '../users/User'  # Avoid mutual inclusion cycles
  Achievement = require '../achievements/Achievement'

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

          worth = achievement.get('worth')
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
              expFunction = achievement.getExpFunction()
              earned.notified = false
              earned.achievedAmount = newAmount
              earned.earnedPoints = (expFunction(newAmount) - expFunction(originalAmount)) * worth
              earned.previouslyAchievedAmount = originalAmount
              EarnedAchievement.update {achievement: earned.achievement, user: earned.user}, earned, {upsert: true}, (err) ->
                return log.debug err if err?

              earnedPoints = earned.earnedPoints
              log.debug earnedPoints
              wrapUp()

          else # not alreadyAchieved
            log.debug 'Creating a new earned achievement called \'' + (achievement.get 'name') + '\' for ' + userID
            earned.earnedPoints = worth
            (new EarnedAchievement(earned)).save (err, doc) ->
              return log.debug err if err?
              earnedPoints = worth
              wrapUp()

    delete before[doc.id] unless isNew # This assumes everything we patch has a _id
    return

module.exports.loadAchievements = ->
  achievements = {}
  Achievement = require '../achievements/Achievement'
  query = Achievement.find({})
  query.exec (err, docs) ->
    _.each docs, (achievement) ->
      category = achievement.get 'collection'
      achievements[category] = [] unless category of achievements
      achievements[category].push achievement

AchievablePlugin.loadAchievements()
