/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AIView
require('app/styles/ai/ai.sass')
const RootView = require('views/core/RootView')
const template = require('app/templates/ai/ai')
let ai
try {
  ai = require('../../../node_modules/ai/dist/ai.js')
  require('../../../node_modules/ai/dist/style.css')
} catch (e) {
  console.warn('AI import unavailable; /ai will not work')
  console.warn(e)
  ai = { AI: () => { } }
}
const ContactModal = require('app/views/core/ContactModal')
const SubscribeModal = require('app/views/core/SubscribeModal')
const CreateAccountModal = require('app/views/core/CreateAccountModal')

module.exports = (AIView = (function () {
  AIView = class AIView extends RootView {
    static initClass() {
      this.prototype.id = 'ai-view'
      this.prototype.template = template
    }

    afterInsert() {
      // Undo our 62.5% default HTML font-size here
      $('html').css('font-size', '16px')
      ai.AI({ domElement: this.$el.find('#ai-root')[0] })
      window.handleAICreditLimitReached = this.handleAICreditLimitReached
      return super.afterInsert()
    }

    destroy() {
      // Redo our 62.5% default HTML font-size here
      $('html').css('font-size', '62.5%')
      window.handleAICreditLimitReached = null
      return super.destroy()
    }

    handleAICreditLimitReached (code, body, options = {}) {
      let message = $.i18n.t('play_level.not_enough_credits_bot')
      const creditsLeft = typeof body === 'string' ? JSON.parse(body)?.creditsLeft : body.creditsLeft
      const creditObj = creditsLeft.find((c) => c.creditsLeft <= 0)
      const interval = creditObj.durationKey
      const amount = creditObj.durationAmount
      if (me.isTeacher()) {
        super.openModalView(new ContactModal())
      } else if (me.isAnonymous()) {
        super.openModalView(new CreateAccountModal({ mode: 'signup' }))
      } else if (me.isHomeUser()) {
        if (me.hasSubscription()) {
          message = $.i18n.t('play_level.not_enough_credits_interval', { interval, amount })
        } else {
          super.openModalView(new SubscribeModal())
        }
      } else if (me.isStudent()) {
        if (me.isEnrolled()) {
          message = $.i18n.t('play_level.not_enough_credits_interval', { interval, amount })
        }
      }
      noty({ text: message, type: 'error', timeout: 5000, layout: 'center' })
    }
  }
  AIView.initClass()
  return AIView
})())
