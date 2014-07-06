Achievement = require 'models/Achievement'
Achievements = require 'collections/AchievementCollection'
UserAchievementsView = require 'views/user/achievements'
EarnedAchievement = require 'models/EarnedAchievement'
EarnedAchievementCollection = require 'collections/EarnedAchievementCollection'

fixtures = require '../../fixtures/achievements'


module.exports = ->
  view = new UserAchievementsView {}, me.get '_id'
  view.render()
