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
      achievementSlugsOrIDs = req.body.achievements
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
    onFinished = -> callback arguments... if callback?

    filter = {}
    filter.$or = [
      {_id: $in: achievementIDs},
      {slug: $in: achievementSlugs}
    ] if achievementSlugs? or achievementIDs?

    # Fetch all relevant achievements
    Achievement.find filter, (err, achievements) ->
      log.error err if err?

      # Fetch every single user
      User.find {}, (err, users) ->
        async.each users, ((user, doneWithUser) ->
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
                isRepeatable = achievement.get('proportionalTo')?
                model = mongoose.modelNameByCollection(achievement.get('collection'))
                if not model?
                  log.error "Model with collection '#{achievement.get 'collection'}' doesn't exist."
                  return doneWithAchievement()

                finalQuery = _.clone achievement.get 'query'
                finalQuery.$or = [{}, {}] # Allow both ObjectIDs or hexa string IDs
                finalQuery.$or[0][achievement.userField] = userID
                finalQuery.$or[1][achievement.userField] = ObjectId userID

                model.findOne finalQuery, (err, something) ->
                  return doneWithAchievement() if _.isEmpty something

                  log.debug "Matched an achievement: #{achievement.get 'name'} for #{user.get 'name'}"

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
                    log.error err if err?
                    doneWithAchievement()
              ), saveUserPoints = ->
                # In principle it is enough to deduct the old amount of points and add the new amount,
                # but just to be entirely safe let's start from 0 in case we're updating all of a user's achievements
                return doneWithUser() unless newTotalPoints
                log.debug "Matched a total of #{newTotalPoints} new points"
                if _.isEmpty filter # Completely clean
                  log.debug "Setting this user's score to #{newTotalPoints}"
                  User.update {_id: userID}, {$set: points: newTotalPoints}, {}, (err) ->
                    log.error err if err?
                    doneWithUser()
                else
                  log.debug "Incrementing score for these achievements with #{newTotalPoints - previousPoints}"
                  User.update {_id: userID}, {$inc: points: newTotalPoints - previousPoints}, {}, (err) ->
                    log.error err if err?
                    doneWithUser()
        ), onFinished

module.exports = new EarnedAchievementHandler()
