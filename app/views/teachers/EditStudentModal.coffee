ModalView = require 'views/core/ModalView'
State = require 'models/State'
template = require 'templates/teachers/edit-student-modal'

module.exports = class EditStudentModal extends ModalView
  id: 'edit-student-modal'
  template: template

  events:
    'click .send-recovery-email-btn:not(.disabled)': 'onClickSendRecoveryEmail'
    'click .change-password-btn:not(.disabled)': 'onClickChangePassword'
    'change .new-password-input': 'onChangeNewPassword'

  initialize: ({ @user }) ->
    @utils = require 'core/utils'
    @state = new State({
      emailSent: false
      passwordChanged: false
      newPassword: ""
    })
    @listenTo @state, 'change', @render

  onClickSendRecoveryEmail: ->
    email = @user.get('email')
    res = $.post '/auth/reset', {email: email}, =>
      @state.set { emailSent: true }

  onClickChangePassword: ->
    @user.save({ password: @state.get('newPassword') })
    @user.unset('password')
    @listenToOnce @user, 'save:success', ->
      @state.set { passwordChanged: true }

  onChangeNewPassword: (e) ->
    @state.set { newPassword: $(e.currentTarget).text() }
