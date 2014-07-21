UserView = require 'views/kinds/UserView'
template = require 'templates/user/home'
{me} = require 'lib/auth'

module.exports = class MainUserView extends UserView
  id: 'user-home-view'
  template: template

  constructor: (userID, options) ->
    super options

  getRenderData: ->
    context = super()
    context

