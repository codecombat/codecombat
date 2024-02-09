import ModalComponent from 'app/views/core/ModalComponent'
import component from './HackstackPromotionModal.vue'

class HackstackPromotionModalView extends ModalComponent {
  constructor (options = {}) {
    super(options)
    this.propsData = options.propsData
  }
}

HackstackPromotionModalView.prototype.id = 'hackstack-promotion-modal-view'
HackstackPromotionModalView.prototype.template = require('app/templates/core/modal-empty')
HackstackPromotionModalView.prototype.VueComponent = component
HackstackPromotionModalView.prototype.propsData = null
HackstackPromotionModalView.prototype.closesOnClickOutside = true
HackstackPromotionModalView.prototype.closesOnEscape = true

export default HackstackPromotionModalView
