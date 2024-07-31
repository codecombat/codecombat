import ModalComponent from 'app/views/core/ModalComponent'
import component from 'app/views/teachers/components/TestStudentModal.vue'

let TestStudentModal
module.exports = (TestStudentModal = (function () {
  TestStudentModal = class TestStudentModal extends ModalComponent {
    static initClass () {
      this.prototype.id = 'test-student-modal'
      this.prototype.template = require('app/templates/core/modal-empty')
      this.prototype.VueComponent = component
      this.prototype.closesOnClickOutside = true
      this.prototype.closesOnEscape = true
    }

    constructor (id) {
      super({})
      this.propsData = { id }
    }
  }
  TestStudentModal.initClass()
  return TestStudentModal
})())
