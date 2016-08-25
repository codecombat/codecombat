log = require 'winston'
mongoose = require 'mongoose'
Achievement = require './../models/Achievement'
EarnedAchievement = require './../models/EarnedAchievement'
errors = require '../commons/errors'
wrap = require 'co-express'


exports.post = wrap (req, res) ->
  achievementID = req.body.achievement
  triggeredBy = req.body.triggeredBy
  collection = req.body.collection
  if collection isnt 'level.sessions' and not testing # TODO: remove this restriction
    throw new errors.UnprocessableEntity('Only doing level session achievements for now.')

  model = mongoose.modelNameByCollection(collection)

  [achievement, trigger, earned] = yield [
    Achievement.findById(achievementID),
    model.findById(triggeredBy)
    EarnedAchievement.findOne({ achievement: achievementID, user: req.user.id })
  ]

  if not achievement
    throw new errors.NotFound('Could not find achievement.')
  if not trigger
    throw new errors.NotFound('Could not find trigger.')
    
  if achievement.get('proportionalTo') and earned
    earnedAchievementDoc = yield EarnedAchievement.createForAchievement(achievement, trigger, {previouslyEarnedAchievement: earned})
    res.status(201).send((earnedAchievementDoc or earned)?.toObject({req}))

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
    yield req.user.update(update)
  
    return res.status(200).send(earned.toObject({req}))

  else
    earnedAchievementDoc = yield EarnedAchievement.createForAchievement(achievement, trigger)
    if not earnedAchievementDoc
      console.error "Couldn't create achievement", achievement, trigger
      throw new errors.NotFound("Couldn't create achievement")
    res.status(201).send(earnedAchievementDoc.toObject({res}))
  
