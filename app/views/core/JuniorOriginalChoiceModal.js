// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let JuniorOriginalChoiceModal
require('app/styles/modal/junior-original-choice-modal.sass')
const ModalView = require('views/core/ModalView')
const template = require('app/templates/core/junior-original-choice-modal')
const storage = require('core/storage')

// define expectations for good rates before releasing

module.exports = (JuniorOriginalChoiceModal = (function () {
  JuniorOriginalChoiceModal = class JuniorOriginalChoiceModal extends ModalView {
    static initClass () {
      this.prototype.id = 'junior-original-choice-modal'
      this.prototype.template = template
      this.prototype.hasAnimated = false
      this.prototype.events = {
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
      this.trigger('junior-original-choice', 'original')
      this.hide()
    }

    onJuniorButtonClick (e) {
      storage.save('junior-original-choice-seen', true)
      this.trigger('junior-original-choice', 'junior')
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
