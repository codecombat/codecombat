require('app/styles/modal/classic-promotion-modal.sass')
const ModalView = require('views/core/ModalView')
const template = require('app/templates/core/hackstack-promotion-modal')

const HackstackPromotionModal = class HackstackPromotionModal extends ModalView {
  onClickPlayButton (e) {
    window.tracker?.trackEvent('Hackstack Promotion Modal', { action: 'play_click' })
    window.location.href = '/hackstack'
  }
}

HackstackPromotionModal.prototype.id = 'hackstack-promotion-modal'
HackstackPromotionModal.prototype.template = template
HackstackPromotionModal.prototype.plain = true
HackstackPromotionModal.prototype.closesOnClickOutside = true
HackstackPromotionModal.prototype.events = {
  'click .close-modal': 'hide',
  'click .play-button': 'onClickPlayButton',
}

module.exports = HackstackPromotionModal
