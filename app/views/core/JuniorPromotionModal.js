require('app/styles/modal/classic-promotion-modal.sass')
const ModalView = require('views/core/ModalView')
const template = require('app/templates/core/junior-promotion-modal')

const JuniorPromotionModal = class JuniorPromotionModal extends ModalView {
  onClickPlayButton (e) {
    window.tracker.trackEvent('Junior Promotion Modal', { action: 'play_click' })
    window.location.href = '/play/junior'
  }
}

JuniorPromotionModal.prototype.id = 'junior-promotion-modal'
JuniorPromotionModal.prototype.template = template
JuniorPromotionModal.prototype.plain = true
JuniorPromotionModal.prototype.closesOnClickOutside = true
JuniorPromotionModal.prototype.events = {
  'click .close-modal': 'hide',
  'click .play-button': 'onClickPlayButton',
}

module.exports = JuniorPromotionModal
