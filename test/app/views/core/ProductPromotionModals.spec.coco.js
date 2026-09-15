/* eslint-env jasmine */
// World-map product modals (GD-900): the CTA sends players straight into the
// product, and only via a marketing page when linking/registering is needed.
const HackstackPromotionModal = require('views/core/HackstackPromotionModal')
const WorldsPromotionModal = require('views/core/WorldsPromotionModal')
const AILeaguePromotionModal = require('views/core/AILeaguePromotionModal')
const OAuth2Identities = require('collections/OAuth2Identities')
const utils = require('core/utils')

describe('HackstackPromotionModal', () => {
  it('sends the player straight to /ai/play', () => {
    const modal = new HackstackPromotionModal()
    spyOn(modal, 'navigate')
    modal.onClickPlayButton()
    expect(modal.navigate).toHaveBeenCalledWith('/ai/play')
  })
})

describe('WorldsPromotionModal', () => {
  const linkedIdentities = [{ provider: 'roblox', sub: '123' }]

  function makeModal ({ anonymous, identities }) {
    spyOn(me, 'isAnonymous').and.returnValue(anonymous)
    spyOn(OAuth2Identities.prototype, 'fetchForProvider').and.returnValue(Promise.resolve(identities))
    const modal = new WorldsPromotionModal()
    spyOn(modal, 'navigate')
    return modal
  }

  it('sends an anonymous player to the /roblox landing page without checking identities', (done) => {
    const modal = makeModal({ anonymous: true, identities: linkedIdentities })
    modal.onClickPlayButton().then(() => {
      expect(OAuth2Identities.prototype.fetchForProvider).not.toHaveBeenCalled()
      expect(modal.navigate).toHaveBeenCalledWith(WorldsPromotionModal.ROBLOX_LANDING_PATH)
      done()
    })
  })

  it('sends an unlinked player to the /roblox landing page', (done) => {
    const modal = makeModal({ anonymous: false, identities: [] })
    modal.onClickPlayButton().then(() => {
      expect(OAuth2Identities.prototype.fetchForProvider).toHaveBeenCalledWith('roblox')
      expect(modal.navigate).toHaveBeenCalledWith(WorldsPromotionModal.ROBLOX_LANDING_PATH)
      done()
    })
  })

  it('sends a linked player straight to the Roblox game', (done) => {
    const modal = makeModal({ anonymous: false, identities: linkedIdentities })
    modal.onClickPlayButton().then(() => {
      expect(modal.navigate).toHaveBeenCalledWith(WorldsPromotionModal.ROBLOX_GAME_URL)
      done()
    })
  })

  it('falls back to the landing page when the identity check fails', (done) => {
    spyOn(me, 'isAnonymous').and.returnValue(false)
    spyOn(OAuth2Identities.prototype, 'fetchForProvider').and.returnValue(Promise.reject(new Error('boom')))
    const modal = new WorldsPromotionModal()
    spyOn(modal, 'navigate')
    modal.onClickPlayButton().then(() => {
      expect(modal.navigate).toHaveBeenCalledWith(WorldsPromotionModal.ROBLOX_LANDING_PATH)
      done()
    })
  })

  it('navigates once even when the button is clicked twice', (done) => {
    const modal = makeModal({ anonymous: false, identities: linkedIdentities })
    Promise.all([modal.onClickPlayButton(), modal.onClickPlayButton()]).then(() => {
      expect(modal.navigate.calls.count()).toBe(1)
      done()
    })
  })
})

describe('AILeaguePromotionModal', () => {
  function makeModal ({ anonymous = false, registered, arena }) {
    spyOn(me, 'isAnonymous').and.returnValue(anonymous)
    spyOn(me, 'isRegisteredForAILeague').and.returnValue(registered)
    spyOn(utils, 'currentArena').and.returnValue(arena)
    const modal = new AILeaguePromotionModal()
    spyOn(modal, 'navigate')
    return modal
  }

  it('sends an anonymous player to the plain league page, since registration needs an account', () => {
    const modal = makeModal({ anonymous: true, registered: false, arena: { slug: 'chaotic-crossing' } })
    modal.onClickPlayButton()
    expect(modal.navigate).toHaveBeenCalledWith('/league')
  })

  it('sends an unregistered player to the league registration page', () => {
    const modal = makeModal({ registered: false, arena: { slug: 'chaotic-crossing' } })
    modal.onClickPlayButton()
    expect(modal.navigate).toHaveBeenCalledWith(AILeaguePromotionModal.LEAGUE_REGISTRATION_PATH)
  })

  it("sends a registered player to the current arena's ladder", () => {
    const modal = makeModal({ registered: true, arena: { slug: 'chaotic-crossing' } })
    modal.onClickPlayButton()
    expect(modal.navigate).toHaveBeenCalledWith('/play/ladder/chaotic-crossing')
  })

  it('carries the tournament id into the ladder url when the arena has one', () => {
    const modal = makeModal({ registered: true, arena: { slug: 'devour-dash', tournament: 'abc123' } })
    modal.onClickPlayButton()
    expect(modal.navigate).toHaveBeenCalledWith('/play/ladder/devour-dash?tournament=abc123')
  })

  it('falls back to the league page when no arena is active', () => {
    const modal = makeModal({ registered: true, arena: undefined })
    modal.onClickPlayButton()
    expect(modal.navigate).toHaveBeenCalledWith('/league')
  })
})

describe('utils.currentArena', () => {
  it('picks the latest active arena that has not ended', () => {
    const now = new Date()
    const stillRunning = utils.activeArenas().filter(a => a.end > now)
    expect(utils.currentArena()).toEqual(_.last(stillRunning))
  })

  it('narrows by arena type', () => {
    const now = new Date()
    for (const type of ['regular', 'championship']) {
      const expected = _.last(utils.activeArenas().filter(a => a.end > now && a.type === type))
      expect(utils.currentArena(type)).toEqual(expected)
    }
    expect(utils.currentArena('no-such-type')).toBeUndefined()
  })
})
