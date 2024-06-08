// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let StopTrialClassesModal
const ModalComponent = require('views/core/ModalComponent')
const StopTrialClassesComponent = require('./components/StopTrialClassesModal.vue').default

module.exports = (StopTrialClassesModal = (function () {
  StopTrialClassesModal = class StopTrialClassesModal extends ModalComponent {
    static initClass () {
      this.prototype.id = 'StopTrialClasses-modal'
      this.prototype.template = require('app/templates/core/modal-base-flat')
      this.prototype.VueComponent = StopTrialClassesComponent
    }

    constructor (options) {
      super(options)
      this.propsData = {
        hide: () => this.hide()
      }
    }

    destroy () {
      if (typeof this.onDestroy === 'function') {
        this.onDestroy()
      }
      return super.destroy()
    }
  }
  StopTrialClassesModal.initClass()
  return StopTrialClassesModal
})())
