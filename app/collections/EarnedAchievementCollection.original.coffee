CocoCollection = require 'collections/CocoCollection'
EarnedAchievement = require 'models/EarnedAchievement'

module.exports = class EarnedAchievementCollection extends CocoCollection
  model: EarnedAchievement

  initialize: (userID) ->
    @url = "/db/user/#{userID}/achievements"
    super()
