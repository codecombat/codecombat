/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ContactModal
const ModalView = require('views/core/ModalView')
const template = require('templates/core/contact')
const SubscribeModal = require('views/core/SubscribeModal')

const forms = require('core/forms')
const { sendContactMessage } = require('core/contact')

const contactSchema = {
  additionalProperties: false,
  required: ['email', 'message'],
  properties: {
    email: {
      type: 'string',
      maxLength: 100,
      minLength: 1,
      format: 'email'
    },

    message: {
      type: 'string',
      minLength: 1
    }
  }
}

module.exports = (ContactModal = (function () {
  ContactModal = class ContactModal extends ModalView {
    static initClass () {
      this.prototype.id = 'contact-modal'
      this.prototype.template = template
      this.prototype.closeButton = true

      this.prototype.events = {
        'click #contact-submit-button': 'contact',
        'click [data-toggle="coco-modal"][data-target="core/SubscribeModal"]': 'openSubscribeModal'
      }
    }

    openSubscribeModal (e) {
      e.stopPropagation()
      return this.openModalView(new SubscribeModal())
    }

    contact () {
      this.playSound('menu-button-click')
      forms.clearFormAlerts(this.$el)
      let contactMessage = forms.formToObject(this.$el)
      const res = tv4.validateMultiple(contactMessage, contactSchema)
      if (!res.valid) { return forms.applyErrorsToForm(this.$el, res.errors) }
      this.populateBrowserData(contactMessage)
      contactMessage = _.merge(contactMessage, this.options)
      contactMessage.country = me.get('country')
      if (window.tracker != null) {
        window.tracker.trackEvent('Sent Feedback', { message: contactMessage })
      }
      sendContactMessage(contactMessage, this.$el)
      return $.post(`/db/user/${me.id}/track/contact_codecombat`)
    }

    populateBrowserData (context) {
      if ($.browser) {
        context.browser = `${$.browser.platform} ${$.browser.name} ${$.browser.versionNumber}`
      }
      context.screenSize = `${(typeof screen !== 'undefined' && screen !== null ? screen.width : undefined) != null ? (typeof screen !== 'undefined' && screen !== null ? screen.width : undefined) : $(window).width()} x ${(typeof screen !== 'undefined' && screen !== null ? screen.height : undefined) != null ? (typeof screen !== 'undefined' && screen !== null ? screen.height : undefined) : $(window).height()}`
      return context.screenshotURL = this.screenshotURL
    }

    updateScreenshot () {
      if (!this.screenshotURL) { return }
      const screenshotEl = this.$el.find('#contact-screenshot').removeClass('secret')
      screenshotEl.find('a').prop('href', this.screenshotURL.replace('http://codecombat.com/', '/'))
      return screenshotEl.find('img').prop('src', this.screenshotURL.replace('http://codecombat.com/', '/'))
    }
  }
  ContactModal.initClass()
  return ContactModal
})())
