// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CoppaDenyView
require('app/styles/modal/create-account-modal/coppa-deny-view.sass')
const CocoView = require('views/core/CocoView')
const State = require('models/State')
const template = require('app/templates/core/create-account-modal/coppa-deny-view')
const forms = require('core/forms')
const contact = require('core/contact')

module.exports = (CoppaDenyView = (function () {
  CoppaDenyView = class CoppaDenyView extends CocoView {
    static initClass () {
      this.prototype.id = 'coppa-deny-view'
      this.prototype.template = template

      this.prototype.events = {
        'click .send-parent-email-button': 'onClickSendParentEmailButton',
        'change input[name="parentEmail"]': 'onChangeParentEmail',
        'click .back-btn': 'onClickBackButton'
      }
    }

    initialize (param) {
      if (param == null) { param = {} }
      const { signupState } = param
      this.signupState = signupState
      const parentEmail = this.signupState.get('parentEmail') || ''
      this.state = new State({
        parentEmail,
        parentEmailSent: false,
        parentEmailSending: false,
        error: false,
        dontUseOurEmailSilly: /team@codecombat.com/i.test(parentEmail),
      })
      return this.listenTo(this.state, 'all', _.debounce(this.render))
    }

    afterRender () {
      super.afterRender()
      const $blurb = this.$('.parent-email-blurb.render')
      if (!$blurb.length) { return }
      const emailLink = '<a href="mailto:team@codecombat.com">team@codecombat.com</a>'
      $blurb.html($.i18n.t('signup.parent_email_excited_blurb').replace('{{email_link}}', emailLink))
    }

    onChangeParentEmail (e) {
      const parentEmail = $(e.currentTarget).val()
      this.signupState.set({ parentEmail }, { silent: true })
      return this.state.set({
        parentEmail,
        dontUseOurEmailSilly: /team@codecombat.com/i.test(parentEmail),
        error: false,
      })
    }

    trackIndividualStepNext (label) {
      if (this.signupState.get('path') !== 'individual') { return }
      return window.tracker?.trackEvent('CreateAccountModal Individual Next Clicked', {
        category: 'Individuals',
        step: 'coppa-deny',
        label,
      })
    }

    onClickSendParentEmailButton (e) {
      e.preventDefault()
      const parentEmail = this.state.get('parentEmail')
      if (!(parentEmail && forms.validateEmail(parentEmail)) || this.state.get('dontUseOurEmailSilly')) {
        return this.state.set({ error: true })
      }
      this.state.set({ parentEmailSending: true, error: false })
      this.trackIndividualStepNext('send-parent-email')
      if (window.tracker != null) {
        window.tracker.trackEvent('CreateAccountModal Individual Parent Email Send Clicked', { category: 'Individuals' })
      }
      return contact.sendParentSignupInstructions(parentEmail)
        .then(() => {
          return this.state.set({ error: false, parentEmailSent: true, parentEmailSending: false })
        }).catch(() => {
          return this.state.set({ error: true, parentEmailSent: false, parentEmailSending: false })
        })
    }

    onClickBackButton () {
      if (this.signupState.get('path') === 'individual') {
        if (window.tracker != null) {
          window.tracker.trackEvent('CreateAccountModal Individual Parent Email Back Clicked', { category: 'Individuals' })
        }
      }
      return this.trigger('nav-back')
    }
  }
  CoppaDenyView.initClass()
  return CoppaDenyView
})())
