RootView = require 'views/kinds/RootView'
template = require 'templates/kinds/user'
User = require 'models/User'

module.exports = class UserView extends RootView
  template: template
  className: 'user-view'

  constructor: (options, nameOrID) ->
    # TODO Ruben Assume ID for now
    user = new User nameOrID
    user.fetch
      success: ->
        console.log 'helabaaa'
      error: (model, response, options) ->
        console.log response
        console.log options

    super options
