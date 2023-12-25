/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LiveClassroomModal
require('app/styles/play/modal/codequest-2020-modal.sass')
const ModalView = require('views/core/ModalView')
const template = require('app/templates/play/modal/codequest-2020-modal.pug')

module.exports = (LiveClassroomModal = (function () {
  LiveClassroomModal = class LiveClassroomModal extends ModalView {
    static initClass () {
      this.prototype.template = template
      this.prototype.id = 'codequest-2020-modal'

      this.prototype.events =
        { 'click #close-modal': 'hide' }
    }
  }
  LiveClassroomModal.initClass()
  return LiveClassroomModal
})())
