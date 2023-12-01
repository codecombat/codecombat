/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let HoC2018VictoryModal
const ModalComponent = require('views/core/ModalComponent')
const HoC2018VictoryComponent = require('./HoC2018VictoryModal.vue').default

module.exports = (HoC2018VictoryModal = (function () {
  HoC2018VictoryModal = class HoC2018VictoryModal extends ModalComponent {
    static initClass () {
      this.prototype.id = 'hoc-victory-modal'
      this.prototype.template = require('app/templates/core/modal-base-flat')
      this.prototype.closeButton = true
      this.prototype.VueComponent = HoC2018VictoryComponent
    }

    constructor (options) {
      super(options)
      if (!options.shareURL) {
        throw new Error('HoC2018VictoryModal requires shareURL value.')
      }
      if (!options.campaign) {
        throw new Error('HoC2018VictoryModal requires campaign slug.')
      }
      this.propsData = {
        navigateCertificate: (name, teacherEmail, shareURL) => {
          const url = `/certificates/${me.id}/anon?campaign=${options.campaign}&username=${name}`
          application.router.navigate(url, { trigger: true })
          if (teacherEmail) {
            return window.tracker != null
              ? window.tracker.trackEvent('HoC2018 completed', {
                name,
                teacherEmail,
                shareURL,
                certificateURL: url,
                userId: me.id
              })
              : undefined
          }
        },
        shareURL: options.shareURL,
        fullName: me.isAnonymous() ? '' : me.broadName()
      }
    }
  }
  HoC2018VictoryModal.initClass()
  return HoC2018VictoryModal
})())
