// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let RecoverModal
require('app/styles/modal/recover-modal.sass')
const ModalView = require('views/core/ModalView')
const template = require('app/templates/core/recover-modal')
const forms = require('core/forms')
const { genericFailure } = require('core/errors')
const utils = require('core/utils')

const filterKeyboardEvents = (allowedEvents, func) => function (...splat) {
  const e = splat[0]
  if (!Array.from(allowedEvents).includes(e.keyCode) && !!e.keyCode) { return }
  return func(...Array.from(splat || []))
}

module.exports = (RecoverModal = (function () {
  RecoverModal = class RecoverModal extends ModalView {
    static initClass () {
      this.prototype.id = 'recover-modal'
      this.prototype.template = template

      this.prototype.events = {
        'click #recover-button': 'recoverAccount',
        'keyup input': 'recoverAccount'
      }

      this.prototype.subscriptions =
        { 'errors:server-error': 'onServerError' }
    }

    afterRender = function () {
      setTimeout(() => {
        const input = this.$el.find('input')
        input.focus()
      }, 500)
    }

    onServerError (e) { // TODO: work error handling into a separate forms system
      return this.disableModalInProgress(this.$el)
    }

    constructor (options) {
      super(options)
      this.successfullyRecovered = this.successfullyRecovered.bind(this)
      this.recoverAccountHandler = filterKeyboardEvents([13], (e) => {
        this.playSound('menu-button-click')
        forms.clearFormAlerts(this.$el)
        const {
          email
        } = forms.formToObject(this.$el)
        if (!email) { return }
        if (!utils.isValidEmail(email)) {
          return noty({ text: $.i18n.t('form_validation_errors.invalidEmail'), layout: 'center', type: 'error', timeout: 3000 })
        }
        const res = $.post('/auth/reset', { email }, this.successfullyRecovered)
        res.fail(genericFailure)
        return this.enableModalInProgress(this.$el)
      }) // TODO: part of forms
    }

    recoverAccount (e) {
      return this.recoverAccountHandler(e)
    }

    successfullyRecovered () {
      this.disableModalInProgress(this.$el)
      this.$el.find('.modal-body:visible').text($.i18n.t('recover.recovery_sent'))
      return this.$el.find('.modal-footer').remove()
    }
  }
  RecoverModal.initClass()
  return RecoverModal
})())
