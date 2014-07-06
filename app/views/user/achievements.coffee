UserView = require 'views/kinds/UserView'
template = require 'templates/user/achievements'
{me} = require 'lib/auth'

module.exports = class UserAchievementsViewe extends UserView
  id: 'user-achievements-view'
  template: template

  constructor: (options, @nameOrID) ->
    super options, @nameOrID

