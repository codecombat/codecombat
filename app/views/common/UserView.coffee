RootView = require 'views/core/RootView'
template = require 'templates/common/user'
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
    @supermodel.loadModel @user, cache: false

  isMe: -> @userID in [me.id, me.get('slug')]

  onLoaded: ->
    @userData = @user unless @user?.isAnonymous()
    @userID = @user.id
    super()

  ifUserNotFound: ->
    console.warn 'user not found'
    @render()
