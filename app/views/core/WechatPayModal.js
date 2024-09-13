import ModalComponent from 'app/views/core/ModalComponent'
import component from './WechatPayModal.vue'

class WechatPayView extends ModalComponent {
  constructor (options = {}) {
    super(options)
    this.propsData = options.propsData
  }
}

WechatPayView.prototype.id = 'wechat-pay-modal'
WechatPayView.prototype.template = require('app/templates/core/modal-empty')
WechatPayView.prototype.VueComponent = component
WechatPayView.prototype.propsData = null
WechatPayView.prototype.closesOnClickOutside = true
WechatPayView.prototype.closesOnEscape = true

export default WechatPayView
