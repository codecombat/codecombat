mongoose = require 'mongoose'
jsonschema = require '../../app/schemas/models/earned_achievement'
util = require '../../app/lib/utils'

EarnedAchievementSchema = new mongoose.Schema({
  notified:
    type: Boolean
    default: false
}, {strict:false})

EarnedAchievementSchema.pre 'save', (next) ->
  @set('changed', Date.now())
  next()

EarnedAchievementSchema.index({user: 1, achievement: 1}, {unique: true, name: 'earned achievement index'})
EarnedAchievementSchema.index({user: 1, changed: -1}, {name: 'latest '})

EarnedAchievementSchema.statics.createForAchievement = (achievement, doc, originalDocObj, done) ->
  User = require '../users/User'
  userObjectID = doc.get(achievement.get('userField'))
  userID = if _.isObject userObjectID then userObjectID.toHexString() else userObjectID # Standardize! Use strings, not ObjectId's

  earned =
    user: userID
    achievement: achievement._id.toHexString()
    achievementName: achievement.get 'name'
    earnedRewards: achievement.get 'rewards'

  worth = achievement.get('worth') ? 10
  earnedPoints = 0
  wrapUp = (earnedAchievementDoc) ->
    # Update user's experience points
    update = {$inc: {points: earnedPoints}}
    for rewardType, rewards of achievement.get('rewards') ? {}
      if rewardType is 'gems'
        update.$inc['earned.gems'] = rewards if rewards
      else if rewards.length
        update.$addToSet ?= {}
        update.$addToSet["earned.#{rewardType}"] = $each: rewards
    User.update {_id: userID}, update, {}, (err, count) ->
      log.error err if err?
      done?(earnedAchievementDoc)

  isRepeatable = achievement.get('proportionalTo')?
  if isRepeatable
    #log.debug 'Upserting repeatable achievement called \'' + (achievement.get 'name') + '\' for ' + userID
    proportionalTo = achievement.get 'proportionalTo'
    originalAmount = if originalDocObj then util.getByPath(originalDocObj, proportionalTo) or 0 else 0
    docObj = doc.toObject()
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
      wrapUp(doc)  

module.exports = EarnedAchievement = mongoose.model('EarnedAchievement', EarnedAchievementSchema)
