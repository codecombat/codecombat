import ModalComponent from 'app/views/core/ModalComponent'
import ModalTeacherCompleteSignup from 'ozaria/site/components/teacher/modal/ModalTeacherCompleteSignup'
import TeacherSignupStoreModule from 'app/views/core/CreateAccountModal/teacher/TeacherSignupStoreModule'
import store from 'core/store'

class TeacherCompleteSignupModal extends ModalComponent {
  // Runs before the constructor is called.
  initialize () {
  }

  destroy () {
    super.destroy()
  }
}

TeacherCompleteSignupModal.prototype.id = 'teacher-complete-signup-modal'
TeacherCompleteSignupModal.prototype.template = require('app/templates/core/modal-empty')
TeacherCompleteSignupModal.prototype.VueComponent = ModalTeacherCompleteSignup
TeacherCompleteSignupModal.prototype.propsData = null

module.exports = TeacherCompleteSignupModal
