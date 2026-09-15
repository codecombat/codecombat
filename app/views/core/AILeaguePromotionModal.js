require('app/styles/modal/ai-league-promotion-modal.sass')
const ModalView = require('views/core/ModalView')
const template = require('app/templates/core/ai-league-promotion-modal')
const utils = require('core/utils')

const LEAGUE_REGISTRATION_PATH = '/league?registering=true'

// Registered players go straight to the current arena's ladder; the rest go
// to the league page with the registration modal open (logged in) or the
// plain league page (anonymous, since registration needs an account).
const AILeaguePromotionModal = class AILeaguePromotionModal extends ModalView {
  getDestination () {
    if (!me.isRegisteredForAILeague()) { return LEAGUE_REGISTRATION_PATH }
    const arena = utils.currentArena()
    if (!arena) { return '/league' }
    let url = `/play/ladder/${arena.slug}`
    if (arena.tournament) { url += `?tournament=${arena.tournament}` }
    return url
  }

  onClickPlayButton (e) {
    const destination = this.getDestination()
    window.tracker?.trackEvent('AI League Promotion Modal', { action: 'play_click', destination })
    this.navigate(destination)
  }

  navigate (url) {
    window.location.href = url
  }
}

AILeaguePromotionModal.LEAGUE_REGISTRATION_PATH = LEAGUE_REGISTRATION_PATH
AILeaguePromotionModal.prototype.id = 'ai-league-promotion-modal'
AILeaguePromotionModal.prototype.template = template
AILeaguePromotionModal.prototype.plain = true
AILeaguePromotionModal.prototype.closesOnClickOutside = true
AILeaguePromotionModal.prototype.events = {
  'click .close-modal': 'hide',
  'click .play-button': 'onClickPlayButton',
}

module.exports = AILeaguePromotionModal
