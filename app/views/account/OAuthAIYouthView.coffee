require('app/styles/account/oauth-aiyouth-view')
RootView = require 'views/core/RootView'
template = require 'templates/account/oauth-aiyouth-view'
utils = require 'core/utils'
User = require 'models/User'

module.exports = class OAuthAIYouthView extends RootView
  id: 'oauth-aiyouth-view'
  template: template

  events:
    'click .confirm-btn': 'onClickConfirmAuth'
    'click .change-btn': 'onClickChangeAccount'


  initialize: ->
    @logoutRedirectURL = false
    @user = new User({_id: me.id})
    @supermodel.trackRequest(@user.fetch()) # use separate, fresh User object instead of `me`
    @username = if me.get('firstName') then me.get('firstName') else me.get('name')
    window.nextURL = window.location.href

    @redirectURL = utils.getQueryVariable('redirect_url')
    #check user already binded

  onClickConfirmAuth: ->
    redirect_url = @redirectURL + '?handle=' + me.id
    console.log("redirect to", redirect_url)
#    window.location.href = redirect_url

  onClickChangeAccount: ->
    me.logout()