/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let PromotionModal
require('app/styles/play/modal/promotion-modal.sass')
const ModalView = require('views/core/ModalView')
const template = require('app/templates/play/modal/promotion-modal')

module.exports = (PromotionModal = (function () {
  PromotionModal = class PromotionModal extends ModalView {
    static initClass () {
      this.prototype.template = template
      this.prototype.id = 'promotion-modal'

      this.prototype.events = {
        'click #close-modal': 'hide',
        'mouseup .promotion-link': 'onClickPromotionLink'
      }
    }

    onClickPromotionLink (e) {
      return (window.tracker != null ? window.tracker.trackEvent('Click Promotion link', { label: 'tarena-winter-tour-link' }) : undefined)
    }
  }
  PromotionModal.initClass()
  return PromotionModal
})())
