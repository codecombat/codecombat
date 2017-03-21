UserAchievementsView = require 'views/user/achievements'

module.exports = ->
  view = new UserAchievementsView {}, 'thisiddoesntexist'

  userRequest = jasmine.Ajax.requests.mostRecent()
  userRequest.response status: 404

  view.render()
