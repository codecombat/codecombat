ModalView = require 'views/core/ModalView'
State = require 'models/State'
template = require 'templates/teachers/edit-student-modal'
auth = require 'core/auth'

module.exports = class EditStudentModal extends ModalView
  id: 'edit-student-modal'
  template: template

  events:
    'click .send-recovery-email-btn:not(.disabled)': 'onClickSendRecoveryEmail'
    'click .change-password-btn:not(.disabled)': 'onClickChangePassword'
    'input .new-password-input': 'onChangeNewPasswordInput'

  initialize: ({ @user, @classroom }) ->
    @supermodel.trackRequest @user.fetch()
    @utils = require 'core/utils'
    @state = new State({
      emailSent: false
      passwordChanged: false
      newPassword: ""
      errorMessage: ""
    })
    @listenTo @state, 'change', @render
    @listenTo @classroom, 'save-password:success', ->
      @state.set { passwordChanged: true, errorMessage: "" }
    @listenTo @classroom, 'save-password:error', (error) ->
      @state.set({ errorMessage: error.message })
      # TODO: Show an error. (password too short)

  onClickSendRecoveryEmail: ->
    email = @user.get('email')
    auth.sendRecoveryEmail(email).then =>
      @state.set { emailSent: true }

  onClickChangePassword: ->
    @classroom.setStudentPassword(@user, @state.get('newPassword'))

  onChangeNewPasswordInput: (e) ->
    @state.set { 
      newPassword: $(e.currentTarget).val()
      emailSent: false
      passwordChanged: false
    }, { silent: true }
    @renderSelectors('.change-password-btn')
