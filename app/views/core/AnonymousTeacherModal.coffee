ModalView = require './ModalView'
template = require 'templates/core/anonymous-teacher-modal'
require('app/styles/modal/anonymous-teacher-modal.sass')
CreateAccountModal = require 'views/core/CreateAccountModal/CreateAccountModal'
forms = require 'core/forms'
errors = require 'core/errors'
State = require 'models/State'
contact = require 'core/contact'

module.exports = class AnonymousTeacherModal extends ModalView
  id: 'anonymous-teacher-modal'
  template: template
  closeButton: true

  events:
    'click #anonymous-teacher-signup-button': 'onClickAnonymousTeacherSignupButton'
    'click #anonymous-teacher-chat-button': 'onClickAnonymousTeacherChatButton'
    'change #anonymous-teacher-email-input': 'onChangeAnonymousTeacherEmailInput'
    'input #anonymous-teacher-email-input': 'onChangeAnonymousTeacherEmailInput'
    'click #anonymous-teacher-email-send-button': 'onClickAnonymousTeacherEmailSendButton'

  initialize: ->
    @state = new State
      checkEmailState: 'none'  # 'none', 'valid', 'invalid'
      sendEmailState: 'none'  # 'none', 'sending', 'sent', 'error'
    @listenTo @state, 'change:checkEmailState', -> @renderSelectors('.email-check', '#anonymous-teacher-email-send-button')
    @listenTo @state, 'change:sendEmailState', -> @renderSelectors('#anonymous-teacher-email-send-button', '#anonymous-teacher-email-error')

  onClickAnonymousTeacherSignupButton: (e) ->
    @openModalView(new CreateAccountModal({startOnPath: 'teacher'}))

  onClickAnonymousTeacherChatButton: (e) ->
    @listenToOnce window.tracker, 'segment-loaded', ->
      Intercom?('showNewMessage')
    me.setRole 'possible teacher'

  getEmail: -> _.string.trim @$('#anonymous-teacher-email-input').val()

  onChangeAnonymousTeacherEmailInput: (e) ->
    email = @getEmail()
    valid = forms.validateEmail(email) and not /codecombat/i.test(email)
    if not email
      @state.set 'checkEmailState', 'none'
    else if valid
      @state.set 'checkEmailState', 'valid'
    else
      @state.set 'checkEmailState', 'invalid'

  onClickAnonymousTeacherEmailSendButton: (e) ->
    @state.set 'sendEmailState', 'sending'
    contact.sendTeacherSignupInstructions(@getEmail())
      .then =>
        @state.set 'sendEmailState', 'sent'
        @hide()
      .catch =>
        @state.set 'sendEmailState', 'error'
