require('app/styles/modal/classic-promotion-modal.sass')
const ModalView = require('views/core/ModalView')
const template = require('app/templates/core/worlds-promotion-modal')

const WorldsPromotionModal = class WorldsPromotionModal extends ModalView {
  onClickPlayButton (e) {
    window.tracker?.trackEvent('Worlds Promotion Modal', { engageAction: 'play_click' })
    window.location.href = 'https://www.roblox.com/games/11704713454/CodeCombat-Worlds-Lua-Coding-RPG'
  }
}

WorldsPromotionModal.prototype.id = 'worlds-promotion-modal'
WorldsPromotionModal.prototype.template = template
WorldsPromotionModal.prototype.plain = true
WorldsPromotionModal.prototype.closesOnClickOutside = true
WorldsPromotionModal.prototype.events = {
  'click .close-modal': 'hide',
  'click .play-button': 'onClickPlayButton',
}

module.exports = WorldsPromotionModal
