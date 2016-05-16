ModalView = require 'views/core/ModalView'
State = require 'models/State'
template = require 'templates/teachers/edit-student-modal'

module.exports = class EditStudentModal extends ModalView
  id: 'edit-student-modal'
  template: template

  events:
    'click .send-recovery-email-btn:not(.disabled)': 'onClickSendRecoveryEmail'
    'click .change-password-btn:not(.disabled)': 'onClickChangePassword'
    'input .new-password-input': 'onChangeNewPasswordInput'

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
    @user.set({ password: @state.get('newPassword') })
    @user.save()
    @user.unset('password')
    @listenToOnce @user, 'save:success', ->
      @state.set { passwordChanged: true }
    @listenTo @user, 'invalid', ->
      # TODO: Show an error.

  onChangeNewPasswordInput: (e) ->
    @state.set { newPassword: $(e.currentTarget).val() }, { silent: true }
