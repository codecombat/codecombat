UserView = require 'views/kinds/UserView'
template = require 'templates/user/home'
{me} = require 'lib/auth'

module.exports = class UserHomeView extends UserView
  id: 'user-home-view'
  template: template

  constructor: (options) ->
    super options

  getRenderData: ->
    context = super()
    context

