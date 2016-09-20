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
    
  finalEarned = yield EarnedAchievement.upsertFor(achievement, trigger, earned, req.user)
  res.status(201).send(finalEarned.toObject({req}))
