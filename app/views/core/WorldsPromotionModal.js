require('app/styles/modal/classic-promotion-modal.sass')
const ModalView = require('views/core/ModalView')
const template = require('app/templates/core/worlds-promotion-modal')
const OAuth2Identities = require('collections/OAuth2Identities')

const ROBLOX_GAME_URL = 'https://www.roblox.com/games/11704713454/CodeCombat-Worlds-Lua-Coding-RPG'
const ROBLOX_LANDING_PATH = '/roblox'

// Players whose CodeCombat account is already linked to Roblox go straight to
// the game. Everyone else (anonymous included) lands on /roblox, where the
// account can be linked first.
const WorldsPromotionModal = class WorldsPromotionModal extends ModalView {
  constructor (options) {
    super(options)
    this.robloxLinked = this.fetchRobloxLinked()
  }

  fetchRobloxLinked () {
    if (me.isAnonymous()) { return Promise.resolve(false) }
    return new OAuth2Identities([]).fetchForProvider('roblox')
      .then(identities => identities.length > 0)
      .catch(() => false)
  }

  async getDestination () {
    const linked = await this.robloxLinked
    return linked ? ROBLOX_GAME_URL : ROBLOX_LANDING_PATH
  }

  async onClickPlayButton (e) {
    if (this.navigating) { return }
    this.navigating = true
    const destination = await this.getDestination()
    window.tracker?.trackEvent('Worlds Promotion Modal', { engageAction: 'play_click', destination })
    this.navigate(destination)
  }

  navigate (url) {
    window.location.href = url
  }
}

WorldsPromotionModal.ROBLOX_GAME_URL = ROBLOX_GAME_URL
WorldsPromotionModal.ROBLOX_LANDING_PATH = ROBLOX_LANDING_PATH
WorldsPromotionModal.prototype.id = 'worlds-promotion-modal'
WorldsPromotionModal.prototype.template = template
WorldsPromotionModal.prototype.plain = true
WorldsPromotionModal.prototype.closesOnClickOutside = true
WorldsPromotionModal.prototype.events = {
  'click .close-modal': 'hide',
  'click .play-button': 'onClickPlayButton',
}

module.exports = WorldsPromotionModal
