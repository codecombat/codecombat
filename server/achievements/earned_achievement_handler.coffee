log = require 'winston'
mongoose = require('mongoose')
EarnedAchievement = require './EarnedAchievement'
Handler = require '../commons/Handler'

class EarnedAchievementHandler extends Handler
  modelClass: EarnedAchievement

  # Don't allow POSTs or anything yet
  hasAccess: (req) ->
    req.method is 'GET'

  recalculate: (req, res) ->
    EarnedAchievement.recalculate (data) => @sendSuccess(res, data)

module.exports = new EarnedAchievementHandler()
