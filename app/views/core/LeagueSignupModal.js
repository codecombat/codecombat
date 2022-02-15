import ModalComponent from 'app/views/core/ModalComponent'
import component from 'app/views/landing-pages/league/components/LeagueSignupModal'

class LeagueSignupModal extends ModalComponent {}

LeagueSignupModal.prototype.id = 'direct-contact-modal'
LeagueSignupModal.prototype.template = require('app/templates/core/modal-empty')
LeagueSignupModal.prototype.VueComponent = component
LeagueSignupModal.prototype.propsData = null
LeagueSignupModal.prototype.closesOnClickOutside = false
LeagueSignupModal.prototype.closesOnEscape = false

export default LeagueSignupModal
