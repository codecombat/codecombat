// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let JuniorModal
require('app/styles/modal/junior-modal.sass')
const ModalView = require('views/core/ModalView')
const template = require('app/templates/core/junior-modal')
const storage = require('core/storage')

// define expectations for good rates before releasing

module.exports = (JuniorModal = (function () {
  JuniorModal = class JuniorModal extends ModalView {
    static initClass () {
      this.prototype.id = 'junior-modal'
      this.prototype.template = template
      this.prototype.hasAnimated = false
      this.prototype.events = {
        'click #close-modal': 'hide',
        'click .submit-button': 'onSubmitButtonClick'
      }
    }

    afterRender () {
      super.afterRender()
      this.setCSSVariables()
      window.addEventListener('resize', this.setCSSVariables)
    }

    onSubmitButtonClick (e) {
      storage.save('roblox-clicked', true)
      window.tracker?.trackEvent('Roblox Explored', { engageAction: 'submit_button_click' })
      this.hide()
    }

    setCSSVariables () {
      const viewportWidth = window.innerWidth || document.documentElement.clientWidth
      document.documentElement.style.setProperty('--vw', `${viewportWidth}`)
    }

    hide () {
      storage.save('roblox-clicked', true)
      super.hide()
    }

    destroy () {
      $('#modal-wrapper').off('mousemove')
      window.removeEventListener('resize', this.setCSSVariables)
      super.destroy()
    }
  }
  JuniorModal.initClass()
  return JuniorModal
})())
