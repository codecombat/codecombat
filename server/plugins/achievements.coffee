mongoose = require('mongoose')
Achievement = require('../achievements/Achievement')
EarnedAchievement = require '../achievements/EarnedAchievement'
LocalMongo = require '../../app/lib/LocalMongo'

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
    previousDocObj = before[doc.id] unless isNew

    category = doc.constructor.modelName

    if category of achievements
      docObj = doc.toObject()
      for achievement in achievements[category]
        query = achievement.get('query')
        isRepeatable = achievement.get('proportionalTo')?
        console.log 'isRepeatable: ' + isRepeatable
        alreadyAchieved = if isNew then false else LocalMongo.matchesQuery previousDocObj, query
        if LocalMongo.matchesQuery(docObj, query) and (isRepeatable or not alreadyAchieved)
          userID = doc.get(achievement.get('userField'))
          console.log 'Creating a new earned achievement for \'' + (achievement.get 'name') + '\' for ' + userID
          earned = new EarnedAchievement(
            user: if _.isObject userID then userID else new mongoose.Types.ObjectId(userID) # Standardize! Use ObjectId's
            achievement: achievement._id
            achievementName: achievement.get 'name'
          )
          console.log earned
          earned.save (err, doc) ->
            console.log 'so something went wrong' if err?

    delete before[doc.id] unless isNew # This assumes everything we patch has a _id
    return