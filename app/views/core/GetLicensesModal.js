import ModalComponent from 'app/views/core/ModalComponent'
import component from 'app/components/common/ModalGetLicenses'

class GetLicensesModal extends ModalComponent {}

GetLicensesModal.prototype.id = 'get-licenses-modal'
GetLicensesModal.prototype.template = require('app/templates/core/modal-empty')
GetLicensesModal.prototype.VueComponent = component
GetLicensesModal.prototype.propsData = { backboneDismissModal: true }
GetLicensesModal.prototype.closesOnClickOutside = true
GetLicensesModal.prototype.closesOnEscape = true

export default GetLicensesModal
