import ModalComponent from 'app/views/core/ModalComponent'
import component from './AskAIHelp.vue'

class AskAIHelpView extends ModalComponent {
  constructor (options = {}) {
    super(options)
    this.propsData = options.propsData
  }

  afterRender () {
    super.afterRender()
    this.vueComponent.$on('ask-ai-clicked', () => {
      this.hide()
    })
  }
}

AskAIHelpView.prototype.id = 'ask-ai-help-modal'
AskAIHelpView.prototype.template = require('app/templates/core/modal-empty')
AskAIHelpView.prototype.VueComponent = component
AskAIHelpView.prototype.propsData = null
AskAIHelpView.prototype.closesOnClickOutside = true
AskAIHelpView.prototype.closesOnEscape = true

export default AskAIHelpView
