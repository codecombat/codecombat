mongoose = require 'mongoose'
jsonschema = require '../../app/schemas/models/earned_achievement'
util = require '../../app/core/utils'
log = require 'winston'
co = require 'co'

EarnedAchievementSchema = new mongoose.Schema({
  notified:
    type: Boolean
    default: false
}, {strict:false})

EarnedAchievementSchema.pre 'save', (next) ->
  @set('changed', new Date())
  next()

EarnedAchievementSchema.index({user: 1, achievement: 1}, {unique: true, name: 'earned achievement index'})
EarnedAchievementSchema.index({user: 1, changed: -1}, {name: 'latest '})


EarnedAchievementSchema.statics.upsertFor = (achievement, trigger, earned, user) ->

  if achievement.get('proportionalTo') and earned
    earnedAchievementDoc = yield @createForAchievement(achievement, trigger, {previouslyEarnedAchievement: earned})
    return earnedAchievementDoc or earned

  else if earned
    achievementEarned = achievement.get('rewards')
    actuallyEarned = earned.get('earnedRewards')
    if not _.isEqual(achievementEarned, actuallyEarned)
      earned.set('earnedRewards', achievementEarned)
      yield earned.save()

    # make sure user has all the levels and items they should have
    update = {}
    for rewardType, rewards of achievement.get('rewards') ? {}
      continue if rewardType is 'gems'
      if rewards.length
        update.$addToSet ?= {}
        update.$addToSet["earned.#{rewardType}"] = { $each: rewards }
    yield user.update(update)
    return earned

  else
    earned = yield @createForAchievement(achievement, trigger)
    if not earned
      console.error "Couldn't create achievement", achievement, trigger
      throw new errors.NotFound("Couldn't create achievement")
    return earned
    
    
EarnedAchievementSchema.statics.createForAchievement = co.wrap (achievement, doc, options={}) ->
  { previouslyEarnedAchievement, originalDocObj } = options
  
  User = require('./User')
  userObjectID = doc.get(achievement.get('userField'))
  userID = if _.isObject userObjectID then userObjectID.toHexString() else userObjectID # Standardize! Use ObjectIds

  earnedAttrs = {
    user: userID
    achievement: achievement._id.toHexString()
    achievementName: achievement.get 'name'
    earnedRewards: achievement.get 'rewards'
  }

  pointWorth = achievement.get('worth') ? 10
  gemWorth = achievement.get('rewards')?.gems ? 0
  earnedPoints = 0
  earnedGems = 0
  earnedDoc = null

  isRepeatable = achievement.get('proportionalTo')?

  if isRepeatable
    proportionalTo = achievement.get('proportionalTo')
    docObj = doc.toObject()
    newAmount = util.getByPath(docObj, proportionalTo) or 0

    if proportionalTo is 'simulatedBy' and newAmount > 0 and not previouslyEarnedAchievement and Math.random() < 0.1
      # Because things like simulatedBy get updated with $inc and not the post-save plugin hook,
      # we (infrequently) fetch the previously earned achievement so we can really update.
      previouslyEarnedAchievement = yield EarnedAchievement.findOne({user: earnedAttrs.user, achievement: earnedAttrs.achievement})

    if previouslyEarnedAchievement
      originalAmount = previouslyEarnedAchievement.get('achievedAmount') or 0
    else if originalDocObj  # This branch could get buggy if unchangedCopy tracking isn't working.
      originalAmount = util.getByPath(originalDocObj, proportionalTo) or 0
    else
      originalAmount = 0

    if originalAmount isnt newAmount
      expFunction = achievement.getExpFunction()
      earnedAttrs.notified = false
      earnedAttrs.achievedAmount = newAmount
      earnedPoints = earnedAttrs.earnedPoints = (expFunction(newAmount) - expFunction(originalAmount)) * pointWorth
      earnedGems = earnedAttrs.earnedGems = (expFunction(newAmount) - expFunction(originalAmount)) * gemWorth ? 0
      earnedAttrs.previouslyAchievedAmount = originalAmount
      yield EarnedAchievement.update({achievement: earnedAttrs.achievement, user: earnedAttrs.user}, earnedAttrs, {upsert: true})
      earnedDoc = new EarnedAchievement(earnedAttrs)

  else # not alreadyAchieved
    earnedAttrs.earnedPoints = pointWorth
    earnedAttrs.earnedGems = gemWorth
    earnedDoc = new EarnedAchievement(earnedAttrs)
    yield earnedDoc.save()
    earnedPoints = pointWorth
    earnedGems = gemWorth

  User.saveActiveUser(userID, "achievement")

  if earnedDoc
    update = {$inc: {points: earnedPoints, 'earned.gems': earnedGems}}
    for rewardType, rewards of achievement.get('rewards') ? {}
      continue if rewardType is 'gems'
      if rewards.length
        update.$addToSet ?= {}
        update.$addToSet["earned.#{rewardType}"] = $each: rewards
    yield User.update({_id: mongoose.Types.ObjectId(userID)}, update, {})

  return earnedDoc

module.exports = EarnedAchievement = mongoose.model('EarnedAchievement', EarnedAchievementSchema)
