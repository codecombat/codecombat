import ModalComponent from 'app/views/core/ModalComponent'
import component from 'ozaria/site/components/common/DirectContactModal'

class DirectContactModal extends ModalComponent {}

DirectContactModal.prototype.id = 'ozaria-direct-contact-modal'
DirectContactModal.prototype.template = require('ozaria/site/templates/core/modal-empty')
DirectContactModal.prototype.VueComponent = component
DirectContactModal.prototype.propsData = null
DirectContactModal.prototype.closesOnClickOutside = false
DirectContactModal.prototype.closesOnEscape = true

export default DirectContactModal
