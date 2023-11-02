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
    window.nextURL = window.location.href  #for login redirect
    @token = utils.getQueryVariable('token')
    @provider = utils.getQueryVariable('provider')

    @providerIsBound = _.any me.get('oAuthIdentities') ? [], (oAuthIdentity) =>
      String(oAuthIdentity.provider) is String(@provider)


  onClickConfirmAuth: ->
    options =
      success: =>
        @succeed = true
        @render()
      error: =>
        noty { text: '绑定失败，请稍后重试或联系大赛技术支持', type: 'error' }

    me.confirmBindAIYouth(@provider, @token, options)

  onClickChangeAccount: ->
    me.logout()