require('app/styles/play/modal/promotion-modal.sass')
ModalView = require('views/core/ModalView')
template = require 'templates/play/modal/promotion-modal'

module.exports = class PromotionModal extends ModalView
  template: template
  id: 'promotion-modal'

  events:
    'click #close-modal': 'hide'
    'mouseup .promotion-link': 'onClickPromotionLink'

  onClickPromotionLink: (e) ->
    window.tracker?.trackEvent 'Click Promotion link', label: 'tarena-winter-tour-link'
