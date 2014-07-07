UserView = require 'views/kinds/UserView'
template = require 'templates/user/achievements'
{me} = require 'lib/auth'
Achievement = require 'models/Achievement'
EarnedAchievement = require 'models/EarnedAchievement'
AchievementCollection = require 'collections/AchievementCollection'
EarnedAchievementCollection = require 'collections/EarnedAchievementCollection'

module.exports = class UserAchievementsView extends UserView
  id: 'user-achievements-view'
  template: template

  events:
    'userLoaded': 'onUserLoaded'

  constructor: (options, nameOrID) ->
    super options, nameOrID

  onUserLoaded: (user) ->
    super user
    @earnedAchievements = @supermodel.loadCollection(new EarnedAchievementCollection(@user), 'achievements').model

