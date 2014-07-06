UserView = require 'views/kinds/UserView'
template = require 'templates/user/achievements'
{me} = require 'lib/auth'
Achievement = require 'models/Achievement'
AchievementCollection = require 'collections/AchievementCollection'

module.exports = class UserAchievementsView extends UserView
  id: 'user-achievements-view'
  template: template

  events:
    'userLoaded': 'onUserLoaded'

  constructor: (options, nameOrID) ->
    super options, nameOrID

  onUserLoaded: (user) ->
    @achievements = @supermodel.loadCollection(new AchievementCollection(@user), 'achievements').model
