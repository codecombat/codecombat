import ModalComponent from 'app/views/core/ModalComponent'
import component from 'app/views/landing-pages/league/components/ClanCreationModal'

class ClanCreationModal extends ModalComponent {}

ClanCreationModal.prototype.id = 'clan-creation-modal'
ClanCreationModal.prototype.template = require('app/templates/core/modal-empty')
ClanCreationModal.prototype.VueComponent = component
ClanCreationModal.prototype.propsData = null
ClanCreationModal.prototype.closesOnClickOutside = false
ClanCreationModal.prototype.closesOnEscape = false

export default ClanCreationModal
