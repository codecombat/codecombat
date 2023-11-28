// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let MaintenanceModal
const ModalComponent = require('views/core/ModalComponent')
const MaintenanceComponent = require('./components/MaintenanceModal.vue').default

module.exports = (MaintenanceModal = (function () {
  MaintenanceModal = class MaintenanceModal extends ModalComponent {
    static initClass () {
      this.prototype.id = 'maintenance-modal'
      this.prototype.template = require('app/templates/core/modal-base-flat')
      this.prototype.VueComponent = MaintenanceComponent
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
  MaintenanceModal.initClass()
  return MaintenanceModal
})())
