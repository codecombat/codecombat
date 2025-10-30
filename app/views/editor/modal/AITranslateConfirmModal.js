let AITranslateConfirmModal
const ModalComponent = require('views/core/ModalComponent')
const AITranslateConfirmComponent = require('./AITranslateConfirmView.vue').default

module.exports = (AITranslateConfirmModal = (function () {
  AITranslateConfirmModal = class AITranslateConfirmModal extends ModalComponent {
    static initClass () {
      this.prototype.id = 'AITranslateConfirm-modal'
      this.prototype.template = require('app/templates/core/modal-base-flat')
      this.prototype.VueComponent = AITranslateConfirmComponent
    }

    constructor (doc, options) {
      super(options)

      this.doc = doc
      this.langs = []
      this.propsData = {
        hide: () => this.hide(),
      }
    }

    afterRender () {
      super.afterRender()
      this.vueComponent.$on('update-langs', (data) => {
        this.langs = data
      })

      this.vueComponent.$on('confirm-translate', async () => {
        await this.doc.aiTranslate(this.langs)
        window.location.reload()
      })
    }

    destroy () {
      if (typeof this.onDestroy === 'function') {
        this.onDestroy()
      }
      return super.destroy()
    }
  }
  AITranslateConfirmModal.initClass()
  return AITranslateConfirmModal
})())
