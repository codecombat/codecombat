require('app/styles/modal/classic-promotion-modal.sass')
const ModalView = require('views/core/ModalView')
const template = require('app/templates/core/hackstack-promotion-modal')

// Players on the world map are already in the game: the CTA goes straight
// into AI HackStack instead of via the /hackstack marketing page.
const HackstackPromotionModal = class HackstackPromotionModal extends ModalView {
  getDestination () {
    return '/ai/play'
  }

  onClickPlayButton (e) {
    const destination = this.getDestination()
    window.tracker?.trackEvent('Hackstack Promotion Modal', { action: 'play_click', destination })
    this.navigate(destination)
  }

  navigate (url) {
    window.location.href = url
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
