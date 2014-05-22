mongoose = require('mongoose')
Achievement = require('../achievements/Achievement')
EarnedAchievement = require '../achievements/EarnedAchievement'
User = require '../users/User'
LocalMongo = require '../../app/lib/LocalMongo'
util = require '../../app/lib/utils'

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

        if newlyAchieved and (not alreadyAchieved or isRepeatable)
          earned = {
            user: userID
            achievement: achievement._id.toHexString()
            achievementName: achievement.get 'name'
          }
          if isRepeatable
            console.log 'Upserting repeatable achievement called \'' + (achievement.get 'name') + '\' for ' + userID
            proportionalTo = achievement.get 'proportionalTo'
            originalAmount = util.getByPath(originalDocObj, proportionalTo) or 0
            newAmount = docObj.get proportionalTo

            if originalAmount isnt newAmount
              earned.notified = false
              earned.achievedAmount = newAmount
              earned.changed = Date.now()
              upsertQuery = EarnedAchievement.findOneAndUpdate earned, upsert:true
              upsertQuery.exec (err, docs) ->
                return console.log err if err?

              # Update user's denormalized score
              userQuery = User.findOne(_id: userID)
              userQuery.exec (err, user) ->
                return console.error(err) if err?
                previousPoints = user.get('points') - achievement.get('worth') * originalAmount
                user.set('points', previousPoints + achievement.get('worth') * newAmount)
          else # not alreadyAchieved
            console.log 'Creating a new earned achievement called \'' + (achievement.get 'name') + '\' for ' + userID
            (new EarnedAchievement(earned)).save (err, doc) ->
              console.log err if err?




    delete before[doc.id] unless isNew # This assumes everything we patch has a _id
    return