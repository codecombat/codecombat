require('app/styles/modal/classic-promotion-modal.sass')
const ModalView = require('views/core/ModalView')
const template = require('app/templates/core/cchome-promotion-modal')

const CCHomePromotionModal = class CCHomePromotionModal extends ModalView {
  onClickPlayButton (e) {
    window.tracker.trackEvent('CCHome Promotion Modal', { action: 'play_click' })
    window.location.href = '/play/'
  }
}

CCHomePromotionModal.prototype.id = 'cchome-promotion-modal'
CCHomePromotionModal.prototype.template = template
CCHomePromotionModal.prototype.plain = true
CCHomePromotionModal.prototype.closesOnClickOutside = true
CCHomePromotionModal.prototype.events = {
  'click .close-modal': 'hide',
  'click .play-button': 'onClickPlayButton',
}

module.exports = CCHomePromotionModal
