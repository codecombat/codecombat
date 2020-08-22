require('app/styles/play/modal/live-classroom-modal.sass')
ModalView = require('views/core/ModalView')
template = require 'templates/play/modal/live-classroom-modal'

module.exports = class LiveClassroomModal extends ModalView
  template: template
  id: 'live-classroom-modal'

  events:
    'click #close-modal': 'hide'
    'mouseup #live-codecombat-link': 'onClickLiveClassesLink'
  
  onClickLiveClassesLink: ->
    window.tracker?.trackEvent 'Click Live Classes link', label: 'live-classes-link'
