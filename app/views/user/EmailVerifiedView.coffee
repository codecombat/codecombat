RootView = require 'views/core/RootView'
State = require 'models/State'
template = require 'templates/user/email-verified-view'
User = require 'models/User'

module.exports = class EmailVerifiedView extends RootView
  id: 'email-verified-view'
  template: template

  events:
    'click .login-button': 'onClickLoginButton'

  initialize: (options, @userID, @verificationCode) ->
    super(options)
    @state = new State(@getInitialState())
    @user = new User({ _id: @userID })
    @user.sendVerificationCode(@verificationCode)

    @listenTo @state, 'change', @render
    @listenTo @user, 'email-verify-success', ->
      @state.set { verifyStatus: 'success' }
      me.fetch()
    @listenTo @user, 'email-verify-error', ->
      @state.set { verifyStatus: 'error' }

  getInitialState: ->
    verifyStatus: 'pending'

  onClickLoginButton: (e) ->
    AuthModal = require 'views/core/AuthModal'
    @openModalView(new AuthModal())
