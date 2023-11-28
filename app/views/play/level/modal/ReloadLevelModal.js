/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ReloadLevelModal
const ModalView = require('views/core/ModalView')
const template = require('app/templates/play/level/modal/reload-level-modal')

module.exports = (ReloadLevelModal = (function () {
  ReloadLevelModal = class ReloadLevelModal extends ModalView {
    static initClass () {
      this.prototype.id = '#reload-level-modal'
      this.prototype.template = template

      this.prototype.events =
        { 'click #restart-level-confirm-button': 'onClickRestart' }
    }

    onClickRestart (e) {
      this.playSound('menu-button-click')
      return Backbone.Mediator.publish('level:restart', {})
    }
  }
  ReloadLevelModal.initClass()
  return ReloadLevelModal
})())
