// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let JuniorClassicChoiceModal
require('app/styles/modal/junior-classic-choice-modal.sass')
const ModalView = require('views/core/ModalView')
const template = require('app/templates/core/junior-classic-choice-modal')
const storage = require('core/storage')

// define expectations for good rates before releasing

module.exports = (JuniorClassicChoiceModal = (function () {
  JuniorClassicChoiceModal = class JuniorClassicChoiceModal extends ModalView {
    static initClass () {
      this.prototype.id = 'junior-classic-choice-modal'
      this.prototype.template = template
      this.prototype.hasAnimated = false
      this.prototype.events = {
        'click #close-modal': 'hide',
        'click .junior-button': 'onJuniorButtonClick',
        'click .classic-button': 'onClassicButtonClick',
      }
    }

    afterRender () {
      super.afterRender()
      this.setCSSVariables()
      window.addEventListener('resize', this.setCSSVariables)
    }

    onClassicButtonClick (e) {
      storage.save('junior-classic-choice-seen', true)
      this.trigger('junior-classic-choice', 'classic')
      this.hide()
    }

    onJuniorButtonClick (e) {
      storage.save('junior-classic-choice-seen', true)
      this.trigger('junior-classic-choice', 'junior')
      this.hide()
    }

    setCSSVariables () {
      const viewportWidth = window.innerWidth || document.documentElement.clientWidth
      document.documentElement.style.setProperty('--vw', `${viewportWidth}`)
    }

    hide () {
      storage.save('junior-classic-choice-seen', true)
      super.hide()
    }

    destroy () {
      $('#modal-wrapper').off('mousemove')
      window.removeEventListener('resize', this.setCSSVariables)
      super.destroy()
    }
  }
  JuniorClassicChoiceModal.initClass()
  return JuniorClassicChoiceModal
})())
