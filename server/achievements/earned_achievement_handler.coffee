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
    @sendSuccess res, {}

  # Returns success: boolean
  # TODO call onFinished
  @recalculate: (callbackOrSlugsOrIDs, onFinished) ->
    if _.isArray callbackOrSlugsOrIDs
      achievementSlugs = (thing for thing in callbackOrSlugsOrIDs when not Handler.isID(thing))
      achievementIDs = (thing for thing in callbackOrSlugsOrIDs when Handler.isID(thing))
    else
      onFinished = callbackOrSlugsOrIDs

    filter = {}
    filter.$or = [
      {_id: $in: achievementIDs},
      {slug: $in: achievementSlugs}
    ] if achievementSlugs? or achievementIDs?

    # Fetch all relevant achievements
    Achievement.find filter, (err, achievements) ->
      return log.error err if err?

      # Fetch every single user
      User.find {}, (err, users) ->
        _.each users, (user) ->
          # Keep track of a user's already achieved in order to set the notified values correctly
          userID = user.get('_id').toHexString()

          # Fetch all of a user's earned achievements
          EarnedAchievement.find {user: userID}, (err, alreadyEarned) ->
            alreadyEarnedIDs = []
            previousPoints = 0
            _.each alreadyEarned, (earned) ->
              if (_.find achievements, (single) -> earned.get('achievement') is single.get('_id').toHexString())
                alreadyEarnedIDs.push earned.get('achievement')
                previousPoints += earned.get 'earnedPoints'

            # TODO maybe also delete earned? Make sure you don't delete too many

            newTotalPoints = 0

            earnedAchievementSaverGenerator = (achievement) -> (callback) ->
              isRepeatable = achievement.get('proportionalTo')?
              model = mongoose.model(achievement.get('collection'))
              if not model?
                log.error "Model #{achievement.get 'collection'} doesn't even exist."
                return callback()

              model.findOne achievement.query, (err, something) ->
                return callback() unless something

                log.debug "Matched an achievement: #{achievement.get 'name'}"

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

                EarnedAchievement.update {achievement: earned.achievement, user: earned.user}, earned, {upsert: true}, (err) ->
                  log.error err if err?
                  callback()

            saveUserPoints = (callback) ->
              # In principle it is enough to deduct the old amount of points and add the new amount,
              # but just to be entirely safe let's start from 0 in case we're updating all of a user's achievements
              log.debug "Matched a total of #{newTotalPoints} new points"
              if _.isEmpty filter # Completely clean
                User.update {_id: userID}, {$set: points: newTotalPoints}, {}, (err) -> log.error err if err?
              else
                log.debug "Incrementing score for these achievements with #{newTotalPoints - previousPoints}"
                User.update {_id: userID}, {$inc: points: newTotalPoints - previousPoints}, {}, (err) -> log.error err if err?

            earnedAchievementSavers = (earnedAchievementSaverGenerator(achievement) for achievement in achievements)
            earnedAchievementSavers.push saveUserPoints

            # We need to have all these database updates chained so we know the final score
            async.series earnedAchievementSavers

module.exports = new EarnedAchievementHandler()
