log = require 'winston'
mongoose = require 'mongoose'
async = require 'async'
Achievement = require './../models/Achievement'
EarnedAchievement = require './../models/EarnedAchievement'
User = require '../models/User'
Handler = require '../commons/Handler'
LocalMongo = require '../../app/lib/LocalMongo'
util = require '../../app/core/utils'
LevelSession = require '../models/LevelSession'
UserPollsRecord = require '../models/UserPollsRecord'

class EarnedAchievementHandler extends Handler
  modelClass: EarnedAchievement

  editableProperties: ['notified']

  # Don't allow POSTs or anything yet
  hasAccess: (req) ->
    return false unless req.user
    req.method in ['GET', 'POST', 'PUT'] # or req.user.isAdmin()

  get: (req, res) ->
    return @getByAchievementIDs(req, res) if req.query.view is 'get-by-achievement-ids'
    unless req.user
      return @sendForbiddenError(res, "You need to have a user to view earned achievements")
    query = { user: req.user._id+''}

    projection = {}
    if req.query.project
      projection[field] = 1 for field in req.query.project.split(',')

    q = EarnedAchievement.find(query, projection)

    skip = parseInt(req.query.skip)
    if skip? and skip < 1000000
      q.skip(skip)

    limit = parseInt(req.query.limit)
    if limit? and limit < 1000
      q.limit(limit)

    q.exec (err, documents) =>
      return @sendDatabaseError(res, err) if err
      documents = (@formatEntity(req, doc) for doc in documents)
      @sendSuccess(res, documents)

  post: (req, res) ->
    achievementID = req.body.achievement
    triggeredBy = req.body.triggeredBy
    collection = req.body.collection
    if collection isnt 'level.sessions'
      return @sendBadInputError(res, 'Only doing level session achievements for now.')

    model = mongoose.modelNameByCollection(collection)

    async.parallel({
      achievement: (callback) ->
        Achievement.findById achievementID, (err, achievement) -> callback(err, achievement)

      trigger: (callback) ->
        model.findById triggeredBy, (err, trigger) -> callback(err, trigger)

      earned: (callback) ->
        q = { achievement: achievementID, user: req.user._id+'' }
        EarnedAchievement.findOne q, (err, earned) -> callback(err, earned)
    }, (err, { achievement, trigger, earned } ) =>
      return @sendDatabaseError(res, err) if err
      if not achievement
        return @sendNotFoundError(res, 'Could not find achievement.')
      else if not trigger
        return @sendNotFoundError(res, 'Could not find trigger.')
      else if achievement.get('proportionalTo') and earned
        EarnedAchievement.createForAchievement(achievement, trigger, null, earned, (earnedAchievementDoc) =>
          @sendCreated(res, (earnedAchievementDoc or earned)?.toObject())
        )
      else if earned
        achievementEarned = achievement.get('rewards')
        actuallyEarned = earned.get('earnedRewards')
        if not _.isEqual(achievementEarned, actuallyEarned)
          earned.set('earnedRewards', achievementEarned)
          earned.save((err) =>
            return @sendDatabaseError(res, err) if err
            @upsertNonNumericRewards(req.user, achievement, (err) =>
              return @sendDatabaseError(res, err) if err
              return @sendSuccess(res, earned.toObject())
            )
          )
        else
          @upsertNonNumericRewards(req.user, achievement, (err) =>
            return @sendDatabaseError(res, err) if err
            return @sendSuccess(res, earned.toObject())
          )
      else
        EarnedAchievement.createForAchievement(achievement, trigger, null, null, (earnedAchievementDoc) =>
          if earnedAchievementDoc
            @sendCreated(res, earnedAchievementDoc.toObject())
          else
            console.error "Couldn't create achievement", achievement, trigger
            @sendNotFoundError res, "Couldn't create achievement"
        )
    )

  upsertNonNumericRewards: (user, achievement, done) ->
    update = {}
    for rewardType, rewards of achievement.get('rewards') ? {}
      continue if rewardType is 'gems'
      if rewards.length
        update.$addToSet ?= {}
        update.$addToSet["earned.#{rewardType}"] = $each: rewards
    User.update {_id: user._id}, update, {}, (err, result) ->
      log.error err if err?
      done?(err)

  getByAchievementIDs: (req, res) ->
    query = { user: req.user._id+''}
    ids = req.query.achievementIDs
    if (not ids) or (ids.length is 0)
      return @sendBadInputError(res, 'For a get-by-achievement-ids request, need to provide ids.')

    ids = ids.split(',')
    for id in ids
      if not Handler.isID(id)
        return @sendBadInputError(res, "Not a MongoDB ObjectId: #{id}")

    query.achievement = {$in: ids}
    EarnedAchievement.find query, (err, earnedAchievements) ->
      return @sendDatabaseError(res, err) if err
      res.send(earnedAchievements)

  recalculate: (req, res) ->
    return @sendForbiddenError(res) unless req.user?.isAdmin()
    onSuccess = (data) => log.debug 'Finished recalculating achievements'
    if 'achievements' of req.body # Support both slugs and IDs separated by commas
      achievementSlugsOrIDs = req.body.achievements
      EarnedAchievementHandler.recalculate achievementSlugsOrIDs, onSuccess
    else
      EarnedAchievementHandler.recalculate onSuccess
    @sendAccepted res, {}

  @recalculate: (callbackOrSlugsOrIDs, callback) ->
    if _.isArray callbackOrSlugsOrIDs # slugs or ids
      achievementSlugs = (thing for thing in callbackOrSlugsOrIDs when not Handler.isID(thing))
      achievementIDs = (thing for thing in callbackOrSlugsOrIDs when Handler.isID(thing))
      recalculatingAll = false
    else # just a callback
      callback = callbackOrSlugsOrIDs
      recalculatingAll = true
    t0 = new Date().getTime()
    total = 100000
    #testUsers = ['livelily+test37@gmail.com']
    if testUsers?
      userQuery = emailLower: {$in: testUsers}
    else
      userQuery = anonymous: false
    User.count userQuery, (err, count) -> total = count

    onFinished = ->
      t1 = new Date().getTime()
      runningTime = ((t1-t0)/1000/60/60).toFixed(2)
      log.info "we finished in #{runningTime} hours"
      callback arguments...

    filter = {}
    filter.$or = [
      {_id: $in: achievementIDs},
      {slug: $in: achievementSlugs}
    ] if achievementSlugs? or achievementIDs?

    # Fetch all relevant achievements
    Achievement.find filter, (err, achievements) ->
      callback?(err) if err?
      callback?(new Error 'No achievements to recalculate') unless achievements.length
      log.info "Recalculating a total of #{achievements.length} achievements..."

      # Fetch every single user. This tends to get big so do it in a streaming fashion.
      userStream = User.find(userQuery).sort('_id').stream()
      streamFinished = false
      usersTotal = 0
      usersFinished = 0
      numberRunning = 0
      doneWithUser = ->
        ++usersFinished
        numberRunning -= 1
        userStream.resume()

        onFinished?() if streamFinished and usersFinished is usersTotal
      userStream.on 'error', (err) -> log.error err
      userStream.on 'close', -> streamFinished = true
      userStream.on 'data',  (user) ->
        ++usersTotal
        numberRunning += 1
        #return doneWithUser() if usersTotal / total < 0.0217  # If it died, we can skip ahead on restart like this.
        userStream.pause() if numberRunning > 20

        # Keep track of a user's already achieved in order to set the notified values correctly
        userID = user.get('_id').toHexString()

        # Fetch a user's poll record so we can get the gems they should have from that.
        UserPollsRecord.findOne {user: userID}, (err, userPollsRecord) ->
          log.error err if err
          pollGems = 0
          for pollID, reward of userPollsRecord?.get('rewards') or {}
            pollGems += Math.ceil 2 * reward.random * reward.level

          # Fetch all of a user's earned achievements
          EarnedAchievement.find {user: userID}, (err, alreadyEarned) ->
            log.error err if err
            alreadyEarnedIDs = []
            previousPoints = 0
            previousRewards = heroes: [], items: [], levels: [], gems: 0
            async.each alreadyEarned, ((earned, doneWithEarned) ->
              if (_.find achievements, (single) -> earned.get('achievement') is single.get('_id').toHexString()) # if already earned
                alreadyEarnedIDs.push earned.get('achievement') + ''
                previousPoints += earned.get 'earnedPoints'
                for rewardType in ['heroes', 'items', 'levels']
                  previousRewards[rewardType] = previousRewards[rewardType].concat(earned.get('earnedRewards')?[rewardType] ? [])
                previousRewards.gems += earned.get('earnedRewards')?.gems ? 0
              doneWithEarned()
            ), (err) -> # After checking already achieved
              log.error err if err
              # TODO maybe also delete earned? Make sure you don't delete too many

              newTotalPoints = 0
              newTotalRewards = heroes: [], items: [], levels: [], gems: 0

              async.each achievements, ((achievement, doneWithAchievement) ->
                isRepeatable = achievement.get('proportionalTo')?
                model = mongoose.modelNameByCollection(achievement.get('collection'))
                return doneWithAchievement new Error "Model with collection '#{achievement.get 'collection'}' doesn't exist." unless model?

                finalQuery = _.clone achievement.get 'query'
                return doneWithAchievement() if _.isEmpty finalQuery
                finalQuery.$or = [{}, {}] # Allow both ObjectIDs or hex string IDs
                finalQuery.$or[0][achievement.userField] = userID
                finalQuery.$or[1][achievement.userField] = mongoose.Types.ObjectId userID

                model.findOne finalQuery, (err, something) ->
                  return doneWithAchievement() if _.isEmpty something

                  #log.debug "Matched an achievement: #{achievement.get 'name'} for #{user.get 'name'}"

                  earned =
                    user: userID
                    achievement: achievement._id.toHexString()
                    achievementName: achievement.get 'name'
                    notified: achievement._id.toHexString() in alreadyEarnedIDs

                  if isRepeatable
                    earned.achievedAmount = util.getByPath(something.toObject(), achievement.get 'proportionalTo') or 0
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

                  EarnedAchievement.update {achievement:earned.achievement, user:earned.user}, earned, {upsert: true}, (err) ->
                    doneWithAchievement err
              ), (err) -> # Wrap up a user, save points
                log.error err if err
                #console.log 'User', user.get('name'), 'had newTotalPoints', newTotalPoints, 'and newTotalRewards', newTotalRewards, 'previousRewards', previousRewards
                return doneWithUser(user) unless newTotalPoints or newTotalRewards.gems or _.some(newTotalRewards, (r) -> r.length)
                #log.debug "Matched a total of #{newTotalPoints} new points"
                #log.debug "Incrementing score for these achievements with #{newTotalPoints - previousPoints}"
                pointDelta = newTotalPoints - previousPoints
                pctDone = (100 * usersFinished / total).toFixed(2)
                log.info "Updated points to #{newTotalPoints} (#{if pointDelta < 0 then '' else '+'}#{pointDelta}) for #{user.get('name') or '???'} (#{user.get('_id')}) (#{pctDone}%)"
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
                #console.log 'recalculatingAll?', recalculatingAll, 'so update is', update, 'secondUpdate', secondUpdate
                User.update {_id: userID}, update, {}, (err) ->
                  log.error err if err?
                  if _.size secondUpdate
                    User.update {_id: userID}, secondUpdate, {}, (err) ->
                      log.error err if err?
                      doneWithUser user
                  else
                    doneWithUser user


module.exports = new EarnedAchievementHandler()
