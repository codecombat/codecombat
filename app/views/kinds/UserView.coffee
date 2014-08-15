RootView = require 'views/kinds/RootView'
template = require 'templates/kinds/user'
User = require 'models/User'

module.exports = class UserView extends RootView
  template: template
  className: 'user-view'
  viewName: null # Used for the breadcrumbs

  constructor: (@userID, options) ->
    super options
    @listenTo @, 'userNotFound', @ifUserNotFound
    @fetchUser @userID

  fetchUser:  ->
    if @isMe()
      @user = me
      @onLoaded()
    @user = new User _id: @userID
    @supermodel.loadModel @user, 'user'

  getRenderData: ->
    context = super()
    context.viewName = @viewName
    context.user = @user unless @user?.isAnonymous()
    context

  isMe: -> @userID is me.id

  onLoaded: ->
    @onUserLoaded @user if @user.loaded and not @userLoaded
    super()

  onUserLoaded: ->
    @userLoaded = true

  ifUserNotFound: ->
    console.warn 'user not found'
    @render()
