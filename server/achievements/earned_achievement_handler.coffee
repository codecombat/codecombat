mongoose = require('mongoose')
EarnedAchievement = require './EarnedAchievement'
Handler = require '../commons/Handler'

class EarnedAchievementHandler extends Handler
  modelClass: EarnedAchievement

  # Don't allow POSTs or anything yet
  hasAccess: (req) ->
    req.method is 'GET'

module.exports = new EarnedAchievementHandler()
