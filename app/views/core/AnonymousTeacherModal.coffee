ModalView = require './ModalView'
template = require 'templates/core/anonymous-teacher-modal'
require('app/styles/modal/anonymous-teacher-modal.sass')
CreateAccountModal = require 'views/core/CreateAccountModal/CreateAccountModal'

module.exports = class AnonymousTeacherModal extends ModalView
  id: 'anonymous-teacher-modal'
  template: template
  closeButton: true

  events:
    'click #anonymous-teacher-signup-button': 'onClickAnonymousTeacherSignupButton'
    'click #anonymous-teacher-chat-button': 'onClickAnonymousTeacherChatButton'
    'change #anonymous-teacher-email-input': 'onChangeAnonymousTeacherEmailInput'
    'click #anonymous-teacher-email-send-button': 'onClickAnonymousTeacherEmailSendButton'

  onClickAnonymousTeacherSignupButton: (e) ->
    @openModalView(new CreateAccountModal({startOnPath: 'teacher'}))

  onClickAnonymousTeacherChatButton: (e) ->
    @listenToOnce window.tracker, 'segment-loaded', ->
      Intercom?('showNewMessage')
    me.setRole 'possible teacher'

  onChangeAnonymousTeacherEmailInput: (e) ->
    console.log 'yo'


  onClickAnonymousTeacherEmailSendButton: (e) ->
    console.log 'yo'
