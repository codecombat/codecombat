import ModalComponent from 'app/views/core/ModalComponent'
import component from 'app/views/teachers/components/TestStudentModal.vue'

let TestStudentModal
module.exports = (TestStudentModal = (function () {
  TestStudentModal = class TestStudentModal extends ModalComponent {
    static initClass () {
      TestStudentModal.prototype.id = 'test-student-modal'
      TestStudentModal.prototype.template = require('app/templates/core/modal-empty')
      TestStudentModal.prototype.VueComponent = component
      TestStudentModal.prototype.closesOnClickOutside = true
      TestStudentModal.prototype.closesOnEscape = true
    }

    constructor (id) {
      super({})
      this.propsData = { id }
    }
  }
  TestStudentModal.initClass()
  return TestStudentModal
})())
