import ModalComponent from 'app/views/core/ModalComponent'
import component from 'app/views/teachers/ModalTeacherDetails'

class TeacherDetailsModal extends ModalComponent {}

TeacherDetailsModal.prototype.id = 'teacher-details-modal'
TeacherDetailsModal.prototype.template = require('app/templates/core/modal-empty')
TeacherDetailsModal.prototype.VueComponent = component
TeacherDetailsModal.prototype.propsData = null
TeacherDetailsModal.prototype.closesOnClickOutside = true
TeacherDetailsModal.prototype.closesOnEscape = true

export default TeacherDetailsModal
