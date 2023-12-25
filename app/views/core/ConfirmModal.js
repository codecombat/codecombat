// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ConfirmModal
const ModalView = require('./ModalView')
const template = require('app/templates/core/confirm-modal')

module.exports = (ConfirmModal = (function () {
  ConfirmModal = class ConfirmModal extends ModalView {
    static initClass () {
      this.prototype.id = 'confirm-modal'
      this.prototype.template = template
      this.prototype.closeButton = true
      this.prototype.closeOnConfirm = true

      this.prototype.events = {
        'click #decline-button': 'onClickDecline',
        'click #confirm-button': 'onClickConfirm'
      }
    }

    initialize (options) {
      return _.assign(this, _.pick(options, 'title', 'body', 'decline', 'confirm', 'closeOnConfirm', 'closeButton'))
    }

    onClickDecline () { return this.trigger('decline') }

    onClickConfirm () { return this.trigger('confirm') }
  }
  ConfirmModal.initClass()
  return ConfirmModal
})())
