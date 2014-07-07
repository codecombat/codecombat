Achievement = require 'models/Achievement'
Achievements = require 'collections/AchievementCollection'
UserAchievementsView = require 'views/user/achievements'
EarnedAchievement = require 'models/EarnedAchievement'
EarnedAchievementCollection = require 'collections/EarnedAchievementCollection'

fixtures = require '../../fixtures/achievements'


module.exports = ->
  view = new UserAchievementsView {}, me.get '_id'

  request = jasmine.Ajax.requests.mostRecent()
  request.response
    status: 200
    responseText: JSON.stringify fixtures.earnedAchievements

  view.render()
