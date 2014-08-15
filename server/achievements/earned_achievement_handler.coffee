log = require 'winston'
mongoose = require 'mongoose'
async = require 'async'
Achievement = require './Achievement'
EarnedAchievement = require './EarnedAchievement'
User = require '../users/User'
Handler = require '../commons/Handler'
LocalMongo = require '../../app/lib/LocalMongo'

class EarnedAchievementHandler extends Handler
  modelClass: EarnedAchievement

  # Don't allow POSTs or anything yet
  hasAccess: (req) ->
    req.method is 'GET' # or req.user.isAdmin()

  recalculate: (req, res) ->
    onSuccess = (data) => log.debug 'Finished recalculating achievements'
    if 'achievements' of req.body # Support both slugs and IDs separated by commas
      achievementSlugsOrIDs = req.body.earnedAchievements
      EarnedAchievementHandler.recalculate achievementSlugsOrIDs, onSuccess
    else
      EarnedAchievementHandler.recalculate onSuccess
    @sendAccepted res, {}

  @recalculate: (callbackOrSlugsOrIDs, callback) ->
    if _.isArray callbackOrSlugsOrIDs # slugs or ids
      achievementSlugs = (thing for thing in callbackOrSlugsOrIDs when not Handler.isID(thing))
      achievementIDs = (thing for thing in callbackOrSlugsOrIDs when Handler.isID(thing))
    else # just a callback
      callback = callbackOrSlugsOrIDs
    t0 = new Date().getTime()
    total = 100000
    User.count {anonymous:false}, (err, count) -> total = count

    onFinished = ->
      t1 = new Date().getTime()
      runningTime = ((t1-t0)/1000/60/60).toFixed(2)
      console.log "we finished in #{runningTime} hours"
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
      userStream = User.find().sort('_id').stream()
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
        userStream.pause() if numberRunning > 20

        # Keep track of a user's already achieved in order to set the notified values correctly
        userID = user.get('_id').toHexString()

        # Fetch all of a user's earned achievements
        EarnedAchievement.find {user: userID}, (err, alreadyEarned) ->
          alreadyEarnedIDs = []
          previousPoints = 0
          async.each alreadyEarned, ((earned, doneWithEarned) ->
            if (_.find achievements, (single) -> earned.get('achievement') is single.get('_id').toHexString()) # if already earned
              alreadyEarnedIDs.push earned.get('achievement')
              previousPoints += earned.get 'earnedPoints'
            doneWithEarned()
          ), -> # After checking already achieved
            # TODO maybe also delete earned? Make sure you don't delete too many

            newTotalPoints = 0

            async.each achievements, ((achievement, doneWithAchievement) ->
              return doneWithAchievement() unless achievement.isRecalculable()

              isRepeatable = achievement.get('proportionalTo')?
              model = mongoose.modelNameByCollection(achievement.get('collection'))
              return doneWithAchievement new Error "Model with collection '#{achievement.get 'collection'}' doesn't exist." unless model?

              finalQuery = _.clone achievement.get 'query'
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
                  notified: achievement._id in alreadyEarnedIDs

                if isRepeatable
                  earned.achievedAmount = something.get(achievement.get 'proportionalTo')
                  earned.previouslyAchievedAmount = 0

                  expFunction = achievement.getExpFunction()
                  newPoints = expFunction(earned.achievedAmount) * achievement.get('worth')
                else
                  newPoints = achievement.get 'worth'

                earned.earnedPoints = newPoints
                newTotalPoints += newPoints

                EarnedAchievement.update {achievement:earned.achievement, user:earned.user}, earned, {upsert: true}, (err) ->
                  doneWithAchievement err
            ), -> # Wrap up a user, save points
              # Since some achievements cannot be recalculated it's important to deduct the old amount of exp
              # and add the new amount, instead of just setting to the new amount
              return doneWithUser(user) unless newTotalPoints
#              log.debug "Matched a total of #{newTotalPoints} new points"
#              log.debug "Incrementing score for these achievements with #{newTotalPoints - previousPoints}"
              pctDone = (100 * usersFinished / total).toFixed(2)
              console.log "Updated points to #{newTotalPoints}(+#{newTotalPoints - previousPoints}) for #{user.get('name') or '???'} (#{user.get('_id')}) (#{pctDone}%)"
              User.update {_id: userID}, {$inc: points: newTotalPoints - previousPoints}, {}, (err) ->
                log.error err if err?
                doneWithUser(user)


module.exports = new EarnedAchievementHandler()
