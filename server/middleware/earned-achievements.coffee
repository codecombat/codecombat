log = require 'winston'
mongoose = require 'mongoose'
Achievement = require './../models/Achievement'
EarnedAchievement = require './../models/EarnedAchievement'
User = require './../models/User'
errors = require '../commons/errors'
wrap = require 'co-express'
utils = require '../lib/utils'
co = require 'co'
UserPollsRecord = require '../models/UserPollsRecord'
appUtils = require '../../app/core/utils'


post = wrap (req, res) ->
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
    
  finalEarned = yield EarnedAchievement.upsertFor(achievement, trigger, earned, req.user)
  res.status(201).send(finalEarned.toObject({req}))
  
  
recalculateRoute = wrap (req, res) ->
  unless req.user?.isAdmin()
    throw new errors.Forbidden() 
  
  { achievements } = req.body # Support both slugs and IDs separated by commas
  promise = recalculate(achievements)
  if global.testing
    yield promise

  res.send(202)
  
  
recalculate = co.wrap (slugsOrIDs, options={}) ->
  if _.isArray slugsOrIDs
    achievementIDs = _.remove(slugsOrIDs, utils.isID)
    achievementSlugs = slugsOrIDs
    recalculatingAll = false
  else
    recalculatingAll = true
  
  t0 = new Date().getTime()
  total = 100000
  if options.testUsers
    userQuery = emailLower: { $in: options.testUsers }
  else
    userQuery = anonymous: false

  total = yield User.count(userQuery)

  filter = {}
  if achievementSlugs or achievementIDs
    filter.$or = [
      {_id: $in: achievementIDs},
      {slug: $in: achievementSlugs}
    ]

  # Fetch all relevant achievements
  achievements = yield Achievement.find filter
  unless achievements.length
    console.log('No achievements to recalculate')
    return
    
  achievementIds = _.pluck(achievements, 'id')
  achievementMap = _.zipObject(achievementIds, achievements)

  log.info "Recalculating a total of #{achievements.length} achievements..."

  yield new Promise (resolve, reject) ->
      
    # Fetch every single user. This tends to get big so do it in a streaming fashion.
    userStream = User.find(userQuery).sort('_id').stream()
    streamFinished = false
    usersTotal = 0
    usersFinished = 0
    numberRunning = 0

    userStream.on 'error', (e) ->
      reject e
    userStream.on 'close', ->
      streamFinished = true
    userStream.on 'data', (user) ->
      co(->
        ++usersTotal
        numberRunning += 1
        userStream.pause() if numberRunning > 20
        yield updateAchievementsForUser(user, achievementMap, recalculatingAll)
        ++usersFinished
        numberRunning -= 1
        userStream.resume()
        resolve() if streamFinished and usersFinished is usersTotal
      ).catch(reject)

  t1 = new Date().getTime()
  runningTime = ((t1-t0)/1000/60/60).toFixed(2)
  log.info "We finished in #{runningTime} hours."



updateAchievementsForUser = co.wrap (user, achievementMap, recalculatingAll) ->
  # Keep track of a user's already achieved in order to set the notified values correctly
  userID = user._id.toHexString()
  
  # Fetch a user's poll record so we can get the gems they should have from that.
  userPollsRecord = yield UserPollsRecord.findOne {user: userID}
  pollGems = 0
  for pollID, reward of userPollsRecord?.get('rewards') or {}
    pollGems += Math.ceil 2 * reward.random * reward.level

  # Fetch all of a user's earned achievements
  alreadyEarned = yield EarnedAchievement.find {user: userID}
  alreadyEarnedIDs = []
  previousPoints = 0
  previousRewards = heroes: [], items: [], levels: [], gems: 0
  
  for earned in alreadyEarned
    achievement = achievementMap[earned.get('achievement')]
    if achievement
      alreadyEarnedIDs.push earned.get('achievement') + ''
      previousPoints += earned.get 'earnedPoints'
      for rewardType in ['heroes', 'items', 'levels']
        previousRewards[rewardType] = previousRewards[rewardType].concat(earned.get('earnedRewards')?[rewardType] ? [])
      previousRewards.gems += earned.get('earnedRewards')?.gems ? 0
  
  # TODO maybe also delete earned? Make sure you don't delete too many

  newTotalPoints = 0
  newTotalRewards = heroes: [], items: [], levels: [], gems: 0

  yield Promise.all(_.map(_.values(achievementMap), co.wrap (achievement) ->
    isRepeatable = achievement.get('proportionalTo')?
    model = mongoose.modelNameByCollection(achievement.get('collection'))
    unless model?
      throw new Error("Model with collection '#{achievement.get 'collection'}' doesn't exist.")

    finalQuery = _.clone achievement.get 'query'
    return if _.isEmpty finalQuery
    finalQuery.$or = [{}, {}] # Allow both ObjectIDs or hex string IDs
    finalQuery.$or[0][achievement.userField] = userID
    finalQuery.$or[1][achievement.userField] = mongoose.Types.ObjectId userID

    something = yield model.findOne finalQuery
    return if _.isEmpty something

    earned =
      user: userID
      achievement: achievement._id.toHexString()
      achievementName: achievement.get 'name'
      notified: achievement.id in alreadyEarnedIDs

    if isRepeatable
      earned.achievedAmount = appUtils.getByPath(something.toObject(), achievement.get 'proportionalTo') or 0
      earned.previouslyAchievedAmount = 0

      expFunction = achievement.getExpFunction()
      newPoints = expFunction(earned.achievedAmount) * achievement.get('worth') ? 10
      newGems = expFunction(earned.achievedAmount) * (achievement.get('rewards')?.gems ? 0)
    else
      newPoints = achievement.get('worth') ? 10
      newGems = achievement.get('rewards')?.gems ? 0

    earned.earnedPoints = newPoints
    newTotalPoints += newPoints

    earned.earnedRewards = achievement.get('rewards')
    for rewardType in ['heroes', 'items', 'levels']
      newTotalRewards[rewardType] = newTotalRewards[rewardType].concat(achievement.get('rewards')?[rewardType] ? [])
    if isRepeatable and earned.earnedRewards
      earned.earnedRewards = _.clone earned.earnedRewards
      earned.earnedRewards.gems = newGems
    newTotalRewards.gems += newGems

    yield EarnedAchievement.update {achievement:earned.achievement, user:earned.user}, earned, {upsert: true}
  ))

  # Wrap up a user, save points
  return unless newTotalPoints or newTotalRewards.gems or _.some(newTotalRewards, (r) -> r.length)
  pointDelta = newTotalPoints - previousPoints
  log.info "Updated points to #{newTotalPoints} (#{if pointDelta < 0 then '' else '+'}#{pointDelta}) for #{user.get('name') or '???'}"
  if recalculatingAll
    update = {$set: {points: newTotalPoints, 'earned.gems': 0, 'earned.heroes': [], 'earned.items': [], 'earned.levels': []}}
  else
    update = {$inc: {points: pointDelta}}
    secondUpdate = {}  # In case we need to pull, then push.

  for rewardType, rewards of newTotalRewards
    updateKey = "earned.#{rewardType}"
    if rewardType is 'gems'
      if recalculatingAll
        update.$set[updateKey] = rewards + pollGems
      else
        update.$inc[updateKey] = rewards - previousRewards.gems
    else
      if recalculatingAll
        update.$set[updateKey] = _.uniq rewards
      else
        previousCounts = _.countBy previousRewards[rewardType]
        newCounts = _.countBy rewards
        relevantRewards = _.union _.keys(previousCounts), _.keys(newCounts)
        for reward in relevantRewards
          [previousCount, newCount] = [previousCounts[reward], newCounts[reward]]
          if newCount and not previousCount
            update.$addToSet ?= {}
            update.$addToSet[updateKey] ?= {$each: []}
            update.$addToSet[updateKey].$each.push reward
          else if previousCount and not newCount
            # Might $pull $each also work here?
            update.$pullAll ?= {}
            update.$pullAll[updateKey] ?= []
            update.$pullAll[updateKey].push reward
        if update.$addToSet?[updateKey] and update.$pullAll?[updateKey]
          # Perform the update in two calls to avoid "MongoError: Cannot update 'earned.levels' and 'earned.levels' at the same time"
          secondUpdate.$addToSet ?= {}
          secondUpdate.$addToSet[updateKey] = update.$addToSet[updateKey]
          delete update.$addToSet[updateKey]
          delete update.$addToSet unless _.size update.$addToSet
  
  yield User.update {_id: userID}, update, {}
  if _.size secondUpdate
    yield User.update {_id: userID}, secondUpdate

module.exports = {
  post
  recalculateRoute
}
