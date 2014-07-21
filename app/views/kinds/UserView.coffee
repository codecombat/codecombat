RootView = require 'views/kinds/RootView'
template = require 'templates/kinds/user'
User = require 'models/User'

module.exports = class UserView extends RootView
  template: template
  className: 'user-view'
  viewName: null # Used for the breadcrumbs

  constructor: (@userID, options) ->
    super options

    @listenTo @, 'userLoaded', @onUserLoaded
    @listenTo @, 'userNotFound', @ifUserNotFound

    @userID ?= me.id
    @fetchUser @userID

  # TODO Ruben make this use the new getByNameOrID as soon as that is merged in
  fetchUser: (id) ->
    User.getByID id, {}, true,
      success: (@user) =>
        @trigger 'userNotFound' unless @user
        @trigger 'userLoaded', @user
      error: =>
        console.debug 'Error while fetching user'
        @trigger 'userNotFound'

  getRenderData: ->
    context = super()
    context.viewName = @viewName
    context.user = @user unless @user?.isAnonymous()
    context

  isMe: -> @userID is me.id

  onUserLoaded: ->
    console.log 'onUserLoaded', @user
    @render()

  ifUserNotFound: ->
    console.warn 'user not found'
    @render()

  onLoaded: ->
    super()
