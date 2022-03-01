require('app/styles/user/user-opt-in-view.sass')
RootView = require 'views/core/RootView'
State = require 'models/State'
template = require 'templates/user/user-opt-in-view'
User = require 'models/User'
utils = require('core/utils')

module.exports = class UserOptInView extends RootView
  id: 'user-opt-in-view'
  template: template

  events:
    'click .keep-me-updated-btn': 'onClickKeepMeUpdated'
    'click .login-button': 'onClickLoginButton'

  initialize: (options, @userID, @verificationCode) ->
    super(options)
    @noDeleteInactiveEU = utils.getQueryVariable('no_delete_inactive_eu', false)
    @keepMeUpdated = utils.getQueryVariable('keep_me_updated', false)
    @promptKeepMeUpdated = utils.getQueryVariable('prompt_keep_me_updated', false)

    @state = new State({status: 'loading'})
    @user = new User({ _id: @userID })

    @user.sendNoDeleteEUVerificationCode(@verificationCode) if @noDeleteInactiveEU
    @user.sendKeepMeUpdatedVerificationCode(@verificationCode) if @keepMeUpdated
    @state.set({status: 'done loading'}) unless @keepMeUpdated or @noDeleteInactiveEU

    @listenTo @state, 'change', @render
    @listenTo @user, 'user-keep-me-updated-success', =>
      @state.set({keepMeUpdatedSuccess: true})
      @state.set({status: 'done loading'})
      me.fetch()
    @listenTo @user, 'user-keep-me-updated-error', =>
      @state.set({keepMeUpdatedError: true})
      @state.set({status: 'done loading'})
    @listenTo @user, 'user-no-delete-eu-success', =>
      @state.set({noDeleteEUSuccess: true})
      @state.set({status: 'done loading'})
      me.fetch()
    @listenTo @user, 'user-no-delete-eu-error', =>
      @state.set({status: 'done loading'})
      @state.set({noDeleteEUError: true})

  onClickKeepMeUpdated: (e) ->
    @user.sendKeepMeUpdatedVerificationCode(@verificationCode)

  onClickLoginButton: (e) ->
    AuthModal = require 'views/core/AuthModal'
    @openModalView(new AuthModal())
