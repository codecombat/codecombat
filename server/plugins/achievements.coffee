mongoose = require('mongoose')
Achievement = require('../achievements/Achievement')
AchievementEarned = require '../achievements/earned/AchievementEarned'

achievements = {}

loadAchievements = ->
  achievements = {}
  query = Achievement.find({})
  query.exec (err, docs) ->
    _.each docs, (achievement) ->
      achievements[achievement.get 'collection'] = [] unless achievement.collection in achievements
      achievements[achievement.get 'collection'].push achievement

loadAchievements()



# TODO make a difference between '$userID' and '$userObjectID' ?
module.exports = AchievablePlugin = (schema, options) ->
  checkForAchievement = (doc) ->
    collectionName = doc.constructor.modelName
    console.log achievements
    for achievement in achievements[collectionName]
      console.log achievement.get 'name'

  fetched = {}

  schema.post 'init', (doc) ->
    fetched[doc.id] = doc
    collectionName = doc.constructor.modelName
    for achievement in achievements[collectionName]
      console.log achievement.get 'name'

  schema.post 'save', (doc) ->
    collectionName = doc.constructor.modelName
    docBefore = fetched?.doc.id
    for achievement in achievements[collectionName]
      "placeholder"
      # continue if init'd and already achieved
      # else if new doc validates, new achievement! make the fucker