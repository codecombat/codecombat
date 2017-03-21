Achievement = require 'models/Achievement'
Achievements = require 'collections/AchievementCollection'
UserAchievementsView = require 'views/user/AchievementsView'
EarnedAchievement = require 'models/EarnedAchievement'
EarnedAchievementCollection = require 'collections/EarnedAchievementCollection'

fixtures = require '../../fixtures/achievements'


module.exports = ->
  view = new UserAchievementsView {}, me.get '_id'

  respond = (request) ->
    return unless request
    if request.url.match /db\/achievement/
      request.response
        status: 200
        responseText: JSON.stringify fixtures.achievements
    else if request.url.match /db\/user\/[a-z0-9]*\/achievements/
      request.response
        status: 200
        responseText: JSON.stringify fixtures.earnedAchievements
    else
      request.response
        status: 404

  _.each jasmine.Ajax.requests.all(), (request) -> respond request

  view.render()
