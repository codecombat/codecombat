import ModalComponent from 'app/views/core/ModalComponent'
import component from 'app/views/teachers/classes/ModalShareWithTeachers'

class ShareWithTeachersModal extends ModalComponent {
  constructor(options = {}) {
    super(options)
    this.propsData = options.propsData
  }
}

ShareWithTeachersModal.prototype.id = 'share-with-teacher-modal'
ShareWithTeachersModal.prototype.template = require('app/templates/core/modal-empty')
ShareWithTeachersModal.prototype.VueComponent = component
ShareWithTeachersModal.prototype.propsData = null
ShareWithTeachersModal.prototype.closesOnClickOutside = true
ShareWithTeachersModal.prototype.closesOnEscape = true

export default ShareWithTeachersModal
