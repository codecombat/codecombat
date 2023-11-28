/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let HowToEnrollModal
require('app/styles/teachers/how-to-enroll-modal.sass')
const ModalView = require('views/core/ModalView')

module.exports = (HowToEnrollModal = (function () {
  HowToEnrollModal = class HowToEnrollModal extends ModalView {
    static initClass () {
      this.prototype.id = 'how-to-enroll-modal'
      this.prototype.template = require('app/templates/teachers/how-to-enroll-modal')
    }
  }
  HowToEnrollModal.initClass()
  return HowToEnrollModal
})())
