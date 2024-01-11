import ModalComponent from 'app/views/core/ModalComponent'
import component from './TeacherStudentsCompletionCoursePromotionModal.vue'

class TeacherStudentsCompletionCoursePromotionModalView extends ModalComponent {
  constructor (options = {}) {
    super(options)
    this.propsData = options.propsData
  }
}

TeacherStudentsCompletionCoursePromotionModalView.prototype.id = 'teacher-students-completion-course-promotion-modal'
TeacherStudentsCompletionCoursePromotionModalView.prototype.template = require('app/templates/core/modal-empty')
TeacherStudentsCompletionCoursePromotionModalView.prototype.VueComponent = component
TeacherStudentsCompletionCoursePromotionModalView.prototype.propsData = null
TeacherStudentsCompletionCoursePromotionModalView.prototype.closesOnClickOutside = true
TeacherStudentsCompletionCoursePromotionModalView.prototype.closesOnEscape = true

export default TeacherStudentsCompletionCoursePromotionModalView
