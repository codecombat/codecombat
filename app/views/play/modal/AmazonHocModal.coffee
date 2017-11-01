ModalView = require('views/core/ModalView')
template = require 'templates/play/modal/amazon-hoc-modal'

module.exports = class AmazonHocModal extends ModalView
  template: template
  id: 'amazon-hoc-modal'

  events:
    'click #close-modal': 'hide'
