require('app/styles/teachers/course-nag-modal.sass')
ModalView = require 'views/core/ModalView'

module.exports = class CourseNagModal extends ModalView
  id: 'course-nag-modal'
  template: require 'app/templates/teachers/course-nag-modal'

