// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AILeaguePromotionModal
require('app/styles/modal/ai-league-promotion-modal.sass')
const ModalView = require('views/core/ModalView')
const template = require('app/templates/core/ai-league-promotion-modal')

module.exports = (AILeaguePromotionModal = (function () {
  AILeaguePromotionModal = class AILeaguePromotionModal extends ModalView {
    static initClass () {
      this.prototype.id = 'ai-league-promotion-modal'
      this.prototype.template = template
      this.prototype.plain = true
      this.prototype.closesOnClickOutside = false

      this.prototype.events = {
        'click .close-modal': 'hide',
        'click .play-button': 'onClickPlayButton'
      }
    }

    constructor (options = {}) {
      super(options)
    }

    onClickPlayButton (e) {
      console.log('play button clicked')
      window.tracker.trackEvent('AI League Promotion Modal', { action: 'play_click' })
      window.location.href = '/league'
    }
  }
  AILeaguePromotionModal.initClass()
  return AILeaguePromotionModal
})())
