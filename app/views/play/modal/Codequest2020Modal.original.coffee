require('app/styles/play/modal/codequest-2020-modal.sass')
ModalView = require('views/core/ModalView')
template = require 'app/templates/play/modal/codequest-2020-modal.pug'

module.exports = class LiveClassroomModal extends ModalView
  template: template
  id: 'codequest-2020-modal'

  events:
    'click #close-modal': 'hide'
