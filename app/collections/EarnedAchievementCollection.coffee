CocoCollection = require 'collections/CocoCollection'
EarnedAchievement = require 'models/EarnedAchievement'

module.exports = class EarnedAchievementCollection extends CocoCollection
  model: EarnedAchievement

  initialize: (me = require('lib/auth').me) ->
    @url = "/db/user/#{me.id}/achievements"

