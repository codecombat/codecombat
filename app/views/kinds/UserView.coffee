RootView = require 'views/kinds/RootView'
template = require 'templates/kinds/user'
User = require 'models/User'

module.exports = class UserView extends RootView
  template: template
  className: 'user-view'

  constructor: (options, @nameOrID) ->
    super options

    @listenTo @, 'userLoaded', @onUserLoaded

    # TODO Ruben Assume ID for now
    @user = User.getByID @nameOrID, {}, true,
      success: =>
        @trigger 'userLoaded', @user

  getRenderData: ->
    context = super()
    context.currentUserView = 'Achievements'
    context.user = @user
    context

  isMe: -> @nameOrID is me.id

  onUserLoaded: ->
