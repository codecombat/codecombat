RootView = require 'views/core/RootView'
template = require 'templates/common/user'
User = require 'models/User'

module.exports = class UserView extends RootView
  template: template
  className: 'user-view'
  viewName: null # Used for the breadcrumbs

  constructor: (@userID, options) ->
    super options

  initialize: (@userID, options) ->
    @listenTo @, 'userNotFound', @ifUserNotFound
    @fetchUser @userID

  fetchUser:  ->
    if @isMe()
      @userData = me
      @onLoaded()
    @userData = new User _id: @userID
    @supermodel.loadModel @userData, cache: false

  isMe: -> @userID in [me.id, me.get('slug')]

  onLoaded: ->
    super()
    @user = @userData unless @userData?.isAnonymous()
    @userID = @userData.id

  ifUserNotFound: ->
    console.warn 'user not found'
    @render()
