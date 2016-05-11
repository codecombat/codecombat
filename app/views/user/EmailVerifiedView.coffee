RootView = require 'views/core/RootView'
State = require 'models/State'
template = require 'templates/user/email-verified-view'
User = require 'models/User'

module.exports = class EmailVerifiedView extends RootView
  id: 'email-verified-view'
  template: template

  initialize: (options, @userID, @verificationCode) ->
    super(options)
    @state = new State(@getInitialState())
    @user = new User({ _id: @userID })
    @user.sendVerificationCode(@verificationCode)

    @listenTo @state, 'change', @render
    @listenTo @user, 'email-verify-success', ->
      @state.set { verifyStatus: 'success' }
    @listenTo @user, 'email-verify-error', ->
      @state.set { verifyStatus: 'error' }

  getInitialState: ->
    verifyStatus: 'pending'
