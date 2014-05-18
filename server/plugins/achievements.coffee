mongoose = require('mongoose')
Achievement = require('../achievements/Achievement')
EarnedAchievement = require '../achievements/EarnedAchievement'
LocalMongo = require '../../app/lib/LocalMongo'
util = require '../../app/lib/utils'

achievements = {}

loadAchievements = ->
  achievements = {}
  query = Achievement.find({})
  query.exec (err, docs) ->
    _.each docs, (achievement) ->
      category = achievement.get 'model'
      achievements[category] = [] unless category of achievements
      achievements[category].push achievement

loadAchievements()


# TODO make a difference between '$userID' and '$userObjectID' ?
module.exports = AchievablePlugin = (schema, options) ->
  checkForAchievement = (doc) ->
    collectionName = doc.constructor.modelName
    console.log achievements
    for achievement in achievements[collectionName]
      console.log achievement.get 'name'

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
        console.log 'isRepeatable: ' + isRepeatable
        alreadyAchieved = if isNew then false else LocalMongo.matchesQuery originalDocObj, query
        newlyAchieved = LocalMongo.matchesQuery(docObj, query)

        userObjectID = doc.get(achievement.get('userField'))
        userID = if _.isObject userObjectID then userObjectID.toHexString() else userObjectID # Standardize! Use strings, not ObjectId's

        if newlyAchieved and not alreadyAchieved
          console.log 'Creating a new earned achievement called \'' + (achievement.get 'name') + '\' for ' + userID
          earned = new EarnedAchievement(
            user: userID
            achievement: achievement._id.toHexString()
            achievementName: achievement.get 'name'
          )
          earned.save (err, doc) ->
            console.log err if err?
        else if newlyAchieved and isRepeatable
          proportionalTo = achievement.get 'proportionalTo'
          originalValue = util.getByPath(originalDocObj, proportionalTo)
          newValue = docObj.get proportionalTo

          if originalValue != newValue
            upsertQuery = EarnedAchievement.findOneAndUpdate
              user: userID
              achievement: achievement._id.toHexString(),
              notified: false
              achievedAmount: newValue
              changed: Date.now(),
              upsert: true
            upsertQuery.exec (err, docs) ->
              console.log err if err?




    delete before[doc.id] unless isNew # This assumes everything we patch has a _id
    return