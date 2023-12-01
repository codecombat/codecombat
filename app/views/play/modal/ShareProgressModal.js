/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ShareProgressModal
require('app/styles/play/modal/share-progress-modal.sass')
const ModalView = require('views/core/ModalView')
const template = require('app/templates/play/modal/share-progress-modal')
const storage = require('core/storage')

module.exports = (ShareProgressModal = (function () {
  ShareProgressModal = class ShareProgressModal extends ModalView {
    static initClass () {
      this.prototype.id = 'share-progress-modal'
      this.prototype.template = template
      this.prototype.plain = true
      this.prototype.closesOnClickOutside = false

      this.prototype.events = {
        'click .close-btn': 'hide',
        'click .continue-link': 'hide',
        'click .send-btn': 'onClickSend'
      }
    }

    onClickSend (e) {
      const email = $('.email-input').val()
      if (!/[\w\.]+@\w+\.\w+/.test(email)) { // eslint-disable-line no-useless-escape
        $('.email-input').parent().addClass('has-error')
        $('.email-invalid').show()
        return false
      }

      const request = this.supermodel.addRequestResource('send_one_time_email', {
        url: '/db/user/-/send_one_time_email',
        data: { email, type: 'share progress modal parent' },
        method: 'POST'
      }, 0)
      request.load()

      storage.save('sent-parent-email', true)
      return this.hide()
    }
  }
  ShareProgressModal.initClass()
  return ShareProgressModal
})())
