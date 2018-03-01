ModalView = require './ModalView'
template = require 'templates/core/anonymous-teacher-modal'
require('app/styles/modal/anonymous-teacher-modal.sass')
CreateAccountModal = require 'views/core/CreateAccountModal/CreateAccountModal'
forms = require 'core/forms'
errors = require 'core/errors'
State = require 'models/State'
contact = require 'core/contact'
storage = require 'core/storage'

module.exports = class AnonymousTeacherModal extends ModalView
  id: 'anonymous-teacher-modal'
  template: template
  closeButton: true

  events:
    'click #anonymous-teacher-signup-button': 'onClickAnonymousTeacherSignupButton'
    'change #anonymous-teacher-email-input': 'onChangeAnonymousTeacherEmailInput'
    'input #anonymous-teacher-email-input': 'onChangeAnonymousTeacherEmailInput'
    'change #anonymous-teacher-student-name-input': 'onChangeAnonymousStudentNameInput'
    'input #anonymous-teacher-student-name-input': 'onChangeAnonymousStudentNameInput'
    'click #anonymous-teacher-email-send-button': 'onClickAnonymousTeacherEmailSendButton'

  initialize: ->
    @state = new State
      checkEmailState: 'none'  # 'none', 'valid', 'invalid'
      checkNameState: 'none'  # 'none', 'valid', 'invalid'
      sendEmailState: 'none'  # 'none', 'sending', 'sent', 'error'
    @state.set 'sendEmailState', 'sent' if storage.load('teacher signup email sent')
    @listenTo @state, 'change:checkEmailState', -> @renderSelectors('.email-check', '#anonymous-teacher-email-send-button')
    @listenTo @state, 'change:checkNameState', -> @renderSelectors('.name-check', '#anonymous-teacher-email-send-button')
    @listenTo @state, 'change:sendEmailState', -> @renderSelectors('#anonymous-teacher-email-send-button', '#anonymous-teacher-email-error')
    window.tracker?.trackEvent 'Anonymous teacher signup modal opened', category: 'World Map', sendEmailState: @state.get('sendEmailState')

  onClickAnonymousTeacherSignupButton: (e) ->
    @openModalView(new CreateAccountModal({startOnPath: 'teacher'}))
    window.tracker?.trackEvent 'Anonymous teacher signup modal teacher signup', category: 'World Map'

  getEmail: -> _.string.trim @$('#anonymous-teacher-email-input').val()

  getStudentName: -> _.string.trim @$('#anonymous-teacher-student-name-input').val()

  onChangeAnonymousTeacherEmailInput: (e) ->
    email = @getEmail()
    valid = forms.validateEmail(email) and not /codecombat/i.test(email)
    if not email
      @state.set 'checkEmailState', 'none'
    else if valid
      @state.set 'checkEmailState', 'valid'
    else
      @state.set 'checkEmailState', 'invalid'

  onChangeAnonymousStudentNameInput: (e) ->
    name = @getStudentName()
    if not name
      @state.set 'checkNameState', 'none'
    else if not _.isEmpty(name)
      @state.set 'checkNameState', 'valid'
    else
      @state.set 'checkNameState', 'invalid'

  onClickAnonymousTeacherEmailSendButton: (e) ->
    return if @state.get 'sendEmailState' is 'sent'
    @state.set 'sendEmailState', 'sending'
    contact.sendTeacherSignupInstructions(@getEmail(), @getStudentName())
      .then =>
        @state.set 'sendEmailState', 'sent'
        storage.save('teacher signup email sent', true)
        window.tracker?.trackEvent 'Anonymous teacher signup modal sent', category: 'World Map', email: @getEmail(), name: @getStudentName()
        @hide()
      .catch =>
        @state.set 'sendEmailState', 'error'
