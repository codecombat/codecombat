let JuniorOriginalChoiceModal
require('app/styles/modal/junior-original-choice-modal.sass')
const ModalView = require('views/core/ModalView')
const template = require('app/templates/core/junior-original-choice-modal')
const storage = require('core/storage')

// define expectations for good rates before releasing

module.exports = (JuniorOriginalChoiceModal = (function () {
  JuniorOriginalChoiceModal = class JuniorOriginalChoiceModal extends ModalView {
    static initClass () {
      JuniorOriginalChoiceModal.prototype.id = 'junior-original-choice-modal'
      JuniorOriginalChoiceModal.prototype.template = template
      JuniorOriginalChoiceModal.prototype.hasAnimated = false
      JuniorOriginalChoiceModal.prototype.events = {
        'click #close-modal': 'hide',
        'click .junior-button': 'onJuniorButtonClick',
        'click .original-button': 'onOriginalButtonClick',
      }
    }

    constructor () {
      super()
      // Bind the method to the instance
      this.setCSSVariables = this.setCSSVariables.bind(this)
    }

    afterRender () {
      super.afterRender()
      this.setCSSVariables()
      window.addEventListener('resize', this.setCSSVariables)
    }

    onOriginalButtonClick (e) {
      storage.save('junior-original-choice-seen', true)
      this.hide()
    }

    onJuniorButtonClick (e) {
      storage.save('junior-original-choice-seen', true)
      window.location.href = '/play/junior'
      this.hide()
    }

    setCSSVariables () {
      const viewportWidth = window.innerWidth || document.documentElement.clientWidth
      document.documentElement.style.setProperty('--vw', `${viewportWidth}`)
    }

    hide () {
      storage.save('junior-original-choice-seen', true)
      super.hide()
    }

    destroy () {
      window.removeEventListener('resize', this.setCSSVariables)
      super.destroy()
    }
  }
  JuniorOriginalChoiceModal.initClass()
  return JuniorOriginalChoiceModal
})())
