ModalView = require './ModalView'
template = require 'templates/core/anonymous-teacher-modal'
require('app/styles/modal/anonymous-teacher-modal.sass')

module.exports = class AnonymousTeacherModal extends ModalView
  id: 'anonymous-teacher-modal'
  template: template
  closeButton: true

  events:
    'click #decline-button': 'onClickDecline'

  onClickDecline: -> @trigger 'decline'
