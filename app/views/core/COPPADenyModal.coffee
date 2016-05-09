ModalView = require 'views/core/ModalView'
template = require 'templates/core/coppa-deny'


module.exports = class COPPADenyModal extends ModalView
  id: 'coppa-deny-modal'
  template: template
  closeButton: true

  constructor: ->
    super()
    window.tracker?.trackEvent 'COPPA Message Shown', category: 'Homepage'