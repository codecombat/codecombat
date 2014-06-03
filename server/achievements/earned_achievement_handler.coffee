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
    onSuccess = (data) => @sendSuccess(res, data)
    if 'achievements' of req.query # Support both slugs and IDs separated by commas
      achievementSlugsOrIDs = req.query.id.split(',')
      EarnedAchievementHandler.recalculate achievementSlugsOrIDs, onSuccess
    else
      EarnedAchievementHandler.recalculate onSuccess
      @sendSuccess res

  # Returns success: boolean
  @recalculate: (callbackOrSlugsOrIDs, callback) ->
    if _.isArray callbackOrSlugsOrIDs
      achievementSlugs = (thing unless Handler.isID(thing) for thing in callbackOrSlugsOrIDs)
      achievementIDs = (thing if Handler.isID(thing) for thing in callbackOrSlugsOrIDs)
    else
      callback = callbackOrSlugsOrIDs

    filter = {}
    filter.$or = [
      _id: $in: achievementIDs
      slug: $in: achievementSlugs
    ] if achievementSlugs? or achievementIDs?

    Achievement.find filter, (err, achievements) ->
      return false and log.error err if err?
      User.find {}, (err, users) ->
        _.each users, (user) ->
          # Keep track of a user's already achieved so as to set the notified values correctly
          userID = user.get('_id').toHexString()
          EarnedAchievement.find {user: userID}, (err, alreadyEarned) ->
            alreadyEarnedIDs = []
            previousPoints = 0
            _.each alreadyEarned, (earned) ->
              alreadyEarnedIDs.push earned.get('achievement')
              previousPoints += earned.get 'earnedPoints'

            # TODO maybe also delete earned? Make sure you don't delete too many

            newTotalPoints = 0

            earnedAchievementSaverGenerator = (achievement) -> (callback) ->
              log.debug 'Checking out tha fancy achievement'
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
                  newTotalPoints += expFunction(earned.achievedAmount) * achievement.get('worth')
                else
                  newTotalPoints += achievement.get 'worth'

                EarnedAchievement.update {achievement:earned.achievement, user:earned.user}, earned, {upsert: true}, (err) ->
                  log.error err if err?
                  callback()

            saveUserPoints = (callback) ->
              # In principle it is enough to deduct the old amount of points and add the new amount,
              # but just to be entirely safe let's start from 0 in case we're updating all of a user's achievements
              log.debug "Matched a total of #{newTotalPoints} new points"
              if _.isEmpty filter # Completely clean
                User.update {_id: userID}, {$set: points: newTotalPoints}, {}, (err) -> log.error err if err?
              else
                User.update {_id: userID}, {$inc: points: newTotalPoints - previousPoints}, {}, (err) -> log.error err if err?

            earnedAchievementSavers = (earnedAchievementSaverGenerator(achievement) for achievement in achievements)
            earnedAchievementSavers.push saveUserPoints

            async.series earnedAchievementSavers


module.exports = new EarnedAchievementHandler()
