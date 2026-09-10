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
const SubscribeModal = require('app/views/core/SubscribeModal')
const CreateAccountModal = require('app/views/core/CreateAccountModal')

module.exports = (AIView = (function () {
  AIView = class AIView extends RootView {
    static initClass () {
      this.prototype.id = 'ai-view'
      this.prototype.template = template
    }

    afterInsert () {
      // Undo our 62.5% default HTML font-size here
      $('html').css('font-size', '16px')
      ai.AI({ domElement: this.$el.find('#ai-root')[0] })
      window.handleAICreditLimitReached = this.handleAICreditLimitReached.bind(this)
      window.AICreditLimitReachedMsg = this.AICreditLimitReachedMsg.bind(this)
      window.openSubscribeModal = this.openSubscribeModal.bind(this)
      window.openCreateAccountModal = this.openCreateAccountModal.bind(this)
      return super.afterInsert()
    }

    destroy () {
      // Redo our 62.5% default HTML font-size here
      $('html').css('font-size', '62.5%')
      window.handleAICreditLimitReached = null
      window.AICreditLimitReachedMsg = null
      window.openSubscribeModal = null
      window.openCreateAccountModal = null
      try {
        ai.AI.unmount?.(this.$el.find('#ai-root')[0])
      } catch (e) {
        console.error('[AIView] Error unmounting AI root', e)
      }
      return super.destroy()
    }

    /**
     * The credit wall for the HackStack SPA. `code` 402 is the redeem endpoint
     * refusing a send; 4020 is the SPA's own credit-line click (same prompts,
     * no toast). Returns which prompt the player got, so the SPA can
     * instrument the wall: 'signup' (anonymous), 'subscribe' (free home),
     * 'interval' (a toast saying when credits refill: premium home, enrolled
     * student), 'sales' (teacher, a new tab), or null (nothing to act on).
     * When a modal opened, `onClose({ converted })` fires once when it closes,
     * `converted` meaning the player registered or subscribed while it was up
     * (GD-861 play-while-you-wait). Signup success reloads the page, so a
     * converted signup close is rarely observed; `window.nextURL` brings the
     * player back to this level after that reload instead of to /play.
     */
    handleAICreditLimitReached (code, body, onClose) {
      if (code !== 402 && code !== 4020) {
        return null
      }
      let message = $.i18n.t('play_level.not_enough_credits_bot')
      const creditsLeft = typeof body === 'string' ? JSON.parse(body)?.creditsLeft : body.creditsLeft
      const creditObj = creditsLeft.find((c) => c.creditsLeft <= 0)
      const interval = creditObj.durationKey
      const amount = creditObj.durationAmount
      let prompt = null
      let modal = null
      if (me.isTeacher()) {
        prompt = 'sales'
        window.tracker?.trackEvent('AI HS prompting sales call')
        window.open('/schools?openContactModal=true&source=ai-hs-credit-limit-reached', '_blank')
      } else if (me.isAnonymous()) {
        prompt = 'signup'
        modal = this.openModalView(new CreateAccountModal({ mode: 'signup' }))
        window.tracker?.trackEvent('AI HS prompting signup', { path: window.location.pathname })
      } else if (me.isHomeUser()) {
        if (me.hasSubscription()) {
          prompt = 'interval'
          message = $.i18n.t('play_level.not_enough_credits_interval', { interval, amount })
        } else {
          prompt = 'subscribe'
          modal = this.openModalView(new SubscribeModal())
          window.tracker?.trackEvent('AI HS prompting subscribe', { path: window.location.pathname })
        }
      } else if (me.isStudent()) {
        if (me.isEnrolled()) {
          prompt = 'interval'
          message = $.i18n.t('play_level.not_enough_credits_interval', { interval, amount })
        }
      }
      if (modal) {
        this.watchCreditWallModal(modal, onClose)
      }
      // In the play-while-you-wait beta what follows a refused send is the whole answer — the
      // modal (signup for anonymous, subscribe for free home) or, for premium home, the SPA's
      // own nudge modal — so no red toast on top of it (control keeps today's toast; the SPA
      // swallows its own error by the same rule). Students get the interval prompt too, but
      // they never read beta.
      const silenced = (modal != null || prompt === 'interval') && me.getPlayWhileYouWaitExperimentValue?.() === 'beta'
      if (code === 402 && !silenced) {
        noty({ text: message, type: 'error', timeout: 10000, layout: 'center' })
      }
      return prompt
    }

    watchCreditWallModal (modal, onClose) {
      const wasAnonymous = me.isAnonymous()
      const wasPremium = me.isPremium()
      // The signup modal (anonymous only) reloads the page on success and would
      // land on /play; come back here instead (same as HeroVictoryModal), and
      // clear it again on a plain close so a later signup from the map is not
      // sent back to this level. The subscribe modal never reloads, so it gets
      // no return URL: one left behind would misroute a later signup.
      const returnURL = wasAnonymous ? window.location.href : null
      if (returnURL) {
        window.nextURL = returnURL
      }
      this.listenToOnce(modal, 'hidden', () => {
        const converted = (wasAnonymous && !me.isAnonymous()) || (!wasPremium && me.isPremium())
        if (returnURL && !converted && window.nextURL === returnURL) {
          window.nextURL = null
        }
        onClose?.({ converted })
      })
    }

    AICreditLimitReachedMsg (body) {
      const creditsLeft = typeof body === 'string' ? JSON.parse(body)?.creditsLeft : body.creditsLeft
      const creditObj = creditsLeft.find((c) => c.creditsLeft <= 0)

      if (me.isAnonymous()) {
        return $.i18n.t('play_level.create_account_to_get_credits')
      } else if (me.isHomeUser() || me.isParentHome()) {
        if (me.isPremium()) {
          return this.creditsZeroMessage(creditObj)
        }
        return $.i18n.t('play_level.get_credits')
      } else if (me.isTeacher()) {
        // todo: teacher licenses checking
        return $.i18n.t('play_level.get_ai_hs_license')
      } else if (me.isStudent()) {
        if (me.isEnrolled()) {
          return this.creditsZeroMessage(creditObj)
        }
        return $.i18n.t('play_level.ask_teacher_for_credits')
      }
    }

    /**
     * The credit line's zero state for players whose credits refill on a schedule (premium
     * home, enrolled students): "Out of credits until {period}." with the period from the
     * operation's interval, or the bare "Out of credits." when the interval has no mapping —
     * never a guessed date (GD-861 amendment; the same sentence in both experiment arms).
     */
    creditsZeroMessage (creditObj) {
      const periods = { day: 'day', week: 'week', month: 'month' }
      const period = creditObj.durationAmount === 1 ? periods[creditObj.durationKey] : null
      return $.i18n.t(period ? `play_level.credits_zero_until_${period}` : 'play_level.credits_zero')
    }

    openSubscribeModal () {
      if (me.isPremium()) {
        return
      }
      this.openModalView(new SubscribeModal())
      window.tracker?.trackEvent('HS open subscribe modal', { path: window.location.pathname })
    }

    openCreateAccountModal () {
      if (!me.isAnonymous()) {
        return
      }
      this.openModalView(new CreateAccountModal({ mode: 'signup' }))
    }
  }
  AIView.initClass()
  return AIView
})())
