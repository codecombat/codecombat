require('app/styles/modal/ai-league-promotion-modal.sass')
const ModalView = require('views/core/ModalView')
const template = require('app/templates/core/ai-league-promotion-modal')

const AILeaguePromotionModal = class AILeaguePromotionModal extends ModalView {
  onClickPlayButton (e) {
    window.tracker.trackEvent('AI League Promotion Modal', { action: 'play_click' })
    window.location.href = '/league'
  }
}

AILeaguePromotionModal.prototype.id = 'ai-league-promotion-modal'
AILeaguePromotionModal.prototype.template = template
AILeaguePromotionModal.prototype.plain = true
AILeaguePromotionModal.prototype.closesOnClickOutside = false
AILeaguePromotionModal.prototype.events = {
  'click .close-modal': 'hide',
  'click .play-button': 'onClickPlayButton'
}

module.exports = AILeaguePromotionModal
